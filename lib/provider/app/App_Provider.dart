import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_sports_calendar/model/app/App_Version_Info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

enum AppProviderState{
  none, ready, update, inspection
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver{
  final _themeKey = 'epin.nadal.themeKey';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // 🔧 초기화 상태 관리
  bool _isInitialized = false;
  bool _isDisposed = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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

  // 🛠️ 안전한 초기화
  Future<AppProviderState> initAppProvider() async{
    if (_isInitialized) {
      debugPrint('🔄 AppProvider 이미 초기화됨 - 스킵');
      return _state;
    }

    if (_isDisposed) {
      debugPrint('❌ AppProvider가 이미 dispose됨');
      return AppProviderState.none;
    }

    try {
      debugPrint('🚀 AppProvider 초기화 시작');

      WidgetsBinding.instance.addObserver(this);
      await _initConnectivityListener();
      await _fetchThemeKey();
      final res = await _fetchAppData();

      _isInitialized = true;
      debugPrint('✅ AppProvider 초기화 완료');

      return res;
    } catch (e) {
      debugPrint('❌ AppProvider 초기화 실패: $e');
      return AppProviderState.none;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    _appState = state;
    notifyListeners(); // 필요 시 UI에 전달
    debugPrint("🔄 App state changed: $state");

    // 포그라운드 진입 시 소켓 재연결
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }

    // 백그라운드로 가면 소켓 연결 해제
    if (state == AppLifecycleState.paused) {
      _handleAppPaused();
    }
  }

  void _handleAppResumed() async {
    if (_isDisposed) return;

    debugPrint("🔄 App resumed - reconnecting socket");
    try {
      await SocketManager.instance.connect();
    } catch (e) {
      debugPrint("❌ Socket reconnection failed: $e");
    }
  }

  void _handleAppPaused() {
    if (_isDisposed) return;

    debugPrint("🔄 App paused - disconnecting socket");
    SocketManager.instance.disconnect();
  }

  //인터넷 연결 상태
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // 🔧 안전한 연결 리스너 초기화
  Future<void> _initConnectivityListener() async {
    try {
      // 기존 구독이 있다면 정리
      await _connectivitySubscription?.cancel();

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        if (_isDisposed) return;

        _handleConnectivityChange(result);
      });

      debugPrint('✅ Connectivity 리스너 초기화 완료');
    } catch (e) {
      debugPrint('❌ Connectivity 리스너 초기화 실패: $e');
      rethrow;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    if (_isDisposed) return;

    final wasOnline = _isOnline;
    final isCurrentlyOnline = !result.contains(ConnectivityResult.none);

    if (wasOnline && !isCurrentlyOnline) {
      // 온라인 → 오프라인
      _showOfflineScreen();
      _isOnline = false;
    } else if (!wasOnline && isCurrentlyOnline) {
      // 오프라인 → 온라인
      _hideOfflineScreen();
      _isOnline = true;
    }

    if (wasOnline != _isOnline) {
      notifyListeners();
      debugPrint("📡 Network changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}");
    }
  }

  void _showOfflineScreen() {
    final context = AppRoute.navigatorKey.currentContext;
    if (context != null && _isOnline) {
      try {
        GoRouter.of(context).push('/loading');
      } catch (e) {
        debugPrint('❌ 오프라인 화면 표시 실패: $e');
      }
    }
  }

  void _hideOfflineScreen() {
    final context = AppRoute.navigatorKey.currentContext;
    if (context != null && !_isOnline) {
      try {
        final location = GoRouter.of(context).state.path;
        if ((location?.contains('/loading') ?? false) && GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        }
      } catch (e) {
        debugPrint('❌ 오프라인 화면 숨기기 실패: $e');
      }
    }
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
      if (!_isDisposed) {
        notifyListeners();
      }
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
    if (_isDisposed) return;

    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheManagerDir = Directory('${cacheDir.path}/libCachedImageData');

      double totalSize = 0;

      if (await cacheManagerDir.exists()) {
        await for (final entity in cacheManagerDir.list(recursive: true, followLinks: false)) {
          if (_isDisposed) break; // dispose 체크

          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              print('Error reading file size: $e');
            }
          }
        }
      }

      if (!_isDisposed) {
        _cacheSize = totalSize / (1024 * 1024); // MB 단위
        notifyListeners();
      }
    } catch (e) {
      print('Error calculating total cache size: $e');
    }
  }

  // 🧹 안전한 리소스 정리
  @override
  void dispose() {
    if (_isDisposed) return;

    debugPrint('🧹 AppProvider dispose 시작');
    _isDisposed = true;

    // 리스너 정리
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    // Observer 제거
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      debugPrint('❌ Observer 제거 실패: $e');
    }

    super.dispose();
    debugPrint('✅ AppProvider dispose 완료');
  }
}