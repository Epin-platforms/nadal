import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_sports_calendar/model/app/App_Version_Info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../manager/project/Import_Manager.dart';

enum AppProviderState{
  none, ready, update, inspection
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver{
  AppProviderState _state = AppProviderState.none;
  AppProviderState get state => _state;

  //앱의 라이프 사이클
  AppLifecycleState _appState = AppLifecycleState.resumed;
  AppLifecycleState get appState => _appState;

  Future<void> initAppProvider() async{
    WidgetsBinding.instance.addObserver(this);
    _initConnectivityListener();
    await _fetchAppData();
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

  Future<void> _fetchAppData() async{
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


}