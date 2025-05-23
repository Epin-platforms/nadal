import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:my_sports_calendar/model/app/App_Version_Info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../manager/project/Import_Manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum AppProviderState{
  none, ready, update, inspection
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver{
  final _themeKey = 'epin.nadal.themeKey';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  _fetchThemeKey() async{
    final pref = await SharedPreferences.getInstance();

    final mode = pref.getString(_themeKey);
    if(mode != null){
      if(mode == 'dark'){
        _themeMode = ThemeMode.dark;
      }else if(mode == 'light'){
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    }
  }

  setTheme(String value) async{
    final pref = await SharedPreferences.getInstance();

    if(value == 'dark'){
      _themeMode = ThemeMode.dark;
      pref.setString(_themeKey, value);
    }else if(value == 'light'){
      _themeMode = ThemeMode.light;
      pref.setString(_themeKey, value);
    }else{
      _themeMode = ThemeMode.system;
      pref.remove(_themeKey);
    }
    notifyListeners();
  }


  AppProviderState _state = AppProviderState.none;
  AppProviderState get state => _state;

  //앱의 라이프 사이클
  AppLifecycleState _appState = AppLifecycleState.resumed;
  AppLifecycleState get appState => _appState;

  Future<AppProviderState> initAppProvider() async{
    WidgetsBinding.instance.addObserver(this);
    _initConnectivityListener();
    _fetchThemeKey();
    final res = await _fetchAppData();
    return res;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    notifyListeners(); // 필요 시 UI에 전달
    debugPrint("🔄 App state changed: $state");

    // 예시: 포그라운드 진입 시 서버 재연결
    if (state == AppLifecycleState.resumed) {
    }

    // 예시: 백그라운드로 가면 리소스 해제
    if (state == AppLifecycleState.paused) {
    }
  }

  //인터넷 연결 상태
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if(_isOnline == true && result.contains(ConnectivityResult.none)){
        if(AppRoute.navigatorKey.currentContext != null && _isOnline == true){
          GoRouter.of(AppRoute.navigatorKey.currentContext!).push('/loading');
        }
        _isOnline = false;
        notifyListeners();
      }else if(_isOnline == false && !result.contains(ConnectivityResult.none)){
        if(AppRoute.navigatorKey.currentContext != null && _isOnline == false){
          final location = GoRouter.of(AppRoute.navigatorKey.currentContext!).state.path;
          if ((location?.contains('/loading') ?? false) && GoRouter.of(AppRoute.navigatorKey.currentContext!).canPop()) {
            GoRouter.of(AppRoute.navigatorKey.currentContext!).pop();
          }
        }

        _isOnline = true;
        notifyListeners();
      }

      debugPrint("📡 Network changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}");
    });
  }

  //앱 데이터 불러오기
  int _lastBuildCode = 0;

  String? _inspectionComment;
  String? get inspectionComment => _inspectionComment;
  DateTime? _inspectionDate;
  DateTime? get inspectionDate => _inspectionDate;

  Future<AppProviderState> _fetchAppData() async{
    try{
      final versionState = await AppVersionInfo.fetchAppVersion(isIOS: Platform.isIOS);

      if(versionState == null){
        throw Exception('인터넷을 확인해주세요.');
      }

      _lastBuildCode = versionState.buildCode;
      if(versionState.inspectionDate.isAfter(DateTime.now())){
        _inspectionComment = versionState.inspectionComment;
        _inspectionDate = versionState.inspectionDate;
        _state = AppProviderState.inspection;
      }else{
        final appBuildCode = await getPackageBuildCode(); //현재 앱의 빌드 번호 가져오기

        if(versionState.buildCode > appBuildCode && versionState.forceUpdate){
          _state = AppProviderState.update;
        }else{
          _state = AppProviderState.ready;
        }
      }
    }catch(error){
      DialogManager.errorHandler(error.toString());
    }finally{
      notifyListeners();
    }

    return _state;
  }

  String _appVersion = '';
  String get appVersion => _appVersion;

  Future<int> getPackageBuildCode() async{
     final PackageInfo appData = await PackageInfo.fromPlatform();
     _appVersion = appData.version;
     final buildCode = int.tryParse(appData.buildNumber);

     if(buildCode == null){
       throw Exception('앱 정보를 읽는데 실패했습니다');
     }

     return buildCode;
  }


  //앱 캐시 보기
  double _cacheSize = 0;
  double get cacheSize => _cacheSize;

  Future<void> getTotalCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheManagerDir = Directory('${cacheDir.path}/libCachedImageData');

      double totalSize = 0;

      if (await cacheManagerDir.exists()) {
        await for (final entity in cacheManagerDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              print('Error reading file size: $e');
            }
          }
        }
      }

      _cacheSize = totalSize / (1024 * 1024); // MB 단위
      notifyListeners();
    } catch (e) {
      print('Error calculating total cache size: $e');
    }
  }

}