import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_sports_calendar/model/app/App_Version_Info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

enum AppProviderState{
  none, ready, update, inspection
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver{
  // 🔧 초기화 상태 관리
  bool _isInitialized = false;
  bool _isDisposed = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AppProviderState _state = AppProviderState.none;
  AppProviderState get state => _state;

  //앱의 라이프 사이클
  AppLifecycleState _appState = AppLifecycleState.resumed;
  AppLifecycleState get appState => _appState;

  // 🔧 백그라운드 복귀 관리
  DateTime? _backgroundTime;
  bool _isReconnecting = false;
  static const Duration _maxBackgroundDuration = Duration(minutes: 5);

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

    final previousState = _appState;
    _appState = state;
    notifyListeners(); // 필요 시 UI에 전달
    debugPrint("🔄 App state changed: $previousState -> $state");

    // 백그라운드로 이동
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleAppPaused();
    }

    // 포그라운드 복귀
    if (state == AppLifecycleState.resumed &&
        (previousState == AppLifecycleState.paused || previousState == AppLifecycleState.inactive)) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() async {
    if (_isDisposed || _isReconnecting) return;

    _isReconnecting = true;
    debugPrint("🔄 App resumed - 백그라운드 복귀 처리 시작");

    try {
      // 🔧 백그라운드 시간 확인
      final backgroundDuration = _backgroundTime != null
          ? DateTime.now().difference(_backgroundTime!)
          : Duration.zero;

      debugPrint("⏱️ 백그라운드 지속 시간: ${backgroundDuration.inMinutes}분");

      // 🔧 소켓 상태 확인 및 강제 재연결
      final socketManager = SocketManager.instance;

      if (!socketManager.isConnected || backgroundDuration > _maxBackgroundDuration) {
        debugPrint("🔌 소켓 강제 재연결 필요");
        await _forceSocketReconnect();
      } else {
        debugPrint("✅ 소켓 연결 상태 양호");
      }

      // 🔧 채팅 데이터 동기화
      await _syncChatDataAfterResume();

      _backgroundTime = null;
    } catch (e) {
      debugPrint("❌ 백그라운드 복귀 처리 실패: $e");
    } finally {
      _isReconnecting = false;
    }
  }

  void _handleAppPaused() {
    if (_isDisposed) return;

    debugPrint("🔄 App paused - 백그라운드 이동");
    _backgroundTime = DateTime.now();

    // 🔧 소켓 연결 유지 (완전히 끊지 않음)
    // SocketManager.instance.disconnect(); // 제거
  }

  // 🔧 강제 소켓 재연결
  Future<void> _forceSocketReconnect() async {
    try {
      final socketManager = SocketManager.instance;

      // 기존 연결 완전히 정리
      debugPrint("🧹 기존 소켓 연결 정리");
      socketManager.disconnect();

      // 잠시 대기 후 재연결
      await Future.delayed(const Duration(milliseconds: 1000));

      debugPrint("🔌 소켓 재연결 시작");
      await socketManager.connect();

      // 연결 확인 대기
      int retryCount = 0;
      while (!socketManager.isConnected && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (socketManager.isConnected) {
        debugPrint("✅ 소켓 재연결 성공");
      } else {
        debugPrint("❌ 소켓 재연결 실패");
      }
    } catch (e) {
      debugPrint("❌ 강제 소켓 재연결 오류: $e");
    }
  }

  // 🔧 채팅 데이터 동기화
  Future<void> _syncChatDataAfterResume() async {
    try {
      final context = AppRoute.context;
      if (context?.mounted != true) return;

      final chatProvider = context!.read<ChatProvider>();

      // 현재 채팅방 확인
      final router = GoRouter.of(context);
      final currentPath = router.state.path;
      final currentRoomId = router.state.pathParameters['roomId'];

      if (currentPath == '/room/:roomId' && currentRoomId != null) {
        final roomId = int.tryParse(currentRoomId);
        if (roomId != null) {
          debugPrint("🔄 현재 채팅방($roomId) 데이터 동기화");
          await chatProvider.refreshRoomFromBackground(roomId);
        }
      }

      // 전체 채팅방 배지 업데이트
      debugPrint("🔄 전체 채팅방 상태 확인");
      // chatProvider에서 배지 업데이트는 자동으로 처리됨

    } catch (e) {
      debugPrint("❌ 채팅 데이터 동기화 오류: $e");
    }
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
      // 오프라인 → 온라인 (네트워크 복구 시 소켓 재연결)
      _hideOfflineScreen();
      _isOnline = true;
      _handleNetworkReconnect();
    }

    if (wasOnline != _isOnline) {
      notifyListeners();
      debugPrint("📡 Network changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}");
    }
  }

  // 🔧 네트워크 복구 시 처리
  void _handleNetworkReconnect() async {
    if (_isDisposed || _isReconnecting) return;

    try {
      debugPrint("📡 네트워크 복구됨 - 소켓 재연결 확인");
      await Future.delayed(const Duration(milliseconds: 1000));

      final socketManager = SocketManager.instance;
      if (!socketManager.isConnected) {
        await _forceSocketReconnect();
      }
    } catch (e) {
      debugPrint("❌ 네트워크 복구 처리 오류: $e");
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