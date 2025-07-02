import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_sports_calendar/screen/home/Nadal_BottomNav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../manager/permission/Permission_Manager.dart';
import '../../manager/project/App_Initialize_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../provider/notification/Notification_Provider.dart';
import '../../provider/app/Advertisement_Provider.dart'; // 🔧 추가

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late HomeProvider homeProvider;
  late NotificationProvider notificationProvider;
  final AppLinks _appLinks = AppLinks();

  // 딥링크 처리 상태 관리
  bool _isInitialized = false;
  String? _pendingRoute;
  int? _pendingNotificationId;

  // 🔧 초기화 상태 관리 개선
  bool _isInitializing = false;
  Timer? _initTimeoutTimer;
  static const Duration _initTimeout = Duration(seconds: 30);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _initTimeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeApp() async {
    if (_isInitializing) return;

    try {
      _isInitializing = true;
      debugPrint('🚀 HomeShell 초기화 시작');

      _initTimeoutTimer = Timer(_initTimeout, () {
        if (!_isInitialized) {
          debugPrint('⏰ 초기화 타임아웃 - 강제 완료');
          _forceInitializationComplete();
        }
      });

      // 1. 딥링크 초기화 (가장 먼저)
      await _initDeepLinks();

      // 🔧 2. 개선된 앱 초기화 시스템 사용
      await _initializeAppSystems();

      // 3. 기타 초기화
      await _initStep();

      // 4. 초기화 완료 후 대기 중인 라우팅 처리
      _processPendingRoute();

      debugPrint('✅ HomeShell 초기화 완료');
    } catch (e) {
      debugPrint('❌ HomeShell 초기화 오류: $e');
      _forceInitializationComplete();
    } finally {
      _initTimeoutTimer?.cancel();
      _isInitializing = false;
    }
  }

  void _forceInitializationComplete() {
    _isInitialized = true;
    _processPendingRoute();
    debugPrint('⚠️ 초기화 강제 완료됨');
  }

  // 🔧 개선된 앱 시스템 초기화
  Future<void> _initializeAppSystems() async {
    if (!mounted) return;

    try {
      debugPrint('🔧 앱 시스템 초기화 시작');

      // AppInitializationManager를 사용한 순차적 초기화
      await AppInitializationManager.initializeApp(context);

      // 🔧 추가 HomeProvider 초기화 (백그라운드)
      _initializeHomeProviderInBackground();

      debugPrint('✅ 앱 시스템 초기화 완료');
    } catch (e) {
      debugPrint('❌ 앱 시스템 초기화 오류: $e');
      throw e;
    }
  }

  // 🔧 HomeProvider 백그라운드 초기화
  void _initializeHomeProviderInBackground() {
    Future.microtask(() async {
      try {
        if (!mounted) return;

        final userProvider = context.read<UserProvider>();

        // 사용자 일정 초기화 (백그라운드)
        await userProvider.fetchMySchedules(DateTime.now());
        debugPrint('✅ 백그라운드 사용자 일정 로드 완료');

        // HomeProvider의 기타 데이터 초기화는 필요할 때만
        // (MyQuickChat에서 한 번만 로드하도록 개선됨)

      } catch (e) {
        debugPrint('❌ HomeProvider 백그라운드 초기화 오류: $e');
      }
    });
  }


  Future<void> _initStep() async {
    if (!mounted) return;

    try {
      // 🔧 알림 초기화를 먼저 완료 (라우팅 처리를 위해)
      await _initNotification();

      // 🔧 기본 권한 체크 (백그라운드에서, ATT 제외)
      _checkPermissionsInBackground();

      // 🔧 **수정: ATT 권한을 명확하게 표시**
      await _requestATTPermissionExplicitly();

      // 🔧 푸시메시지 체크 개선
      await _checkPushMessages();

      _isInitialized = true;
      debugPrint('✅ HomeShell 초기화 단계 완료');
    } catch (e) {
      debugPrint('❌ 초기화 단계 오류: $e');
      _isInitialized = true;
    }
  }
  // 🔧 알림 초기화를 동기적으로 처리
  Future<void> _initNotification() async {
    try {
      await notificationProvider.initialize();
      debugPrint('✅ 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 초기화 오류: $e');
    }
  }

  // 🔧 기본 권한 체크 (ATT 제외)
  void _checkPermissionsInBackground() {
    Future.microtask(() async {
      try {
        if (mounted) {
          // 🔧 Permission_Manager에서 ATT 권한이 제거된 기본 권한들만 요청
          await PermissionManager.checkAndShowPermissions(context);
          debugPrint('✅ 기본 권한 요청 완료 (ATT 제외)');
        }
      } catch (e) {
        debugPrint('❌ 기본 권한 체크 오류: $e');
      }
    });
  }

  // 🔧 광고 ATT 권한 처리 (백그라운드에서)
  Future<void> _requestATTPermissionExplicitly() async {
    try {
      if (!Platform.isIOS || !mounted) return;

      final adProvider = context.read<AdvertisementProvider>();

      // 이미 ATT 초기화가 완료되었는지 확인
      if (adProvider.isATTInitialized) {
        debugPrint('✅ ATT 이미 초기화됨 - 스킵');
        return;
      }

      debugPrint('🔧 ATT 권한 명확하게 요청 시작');

      // ATT 권한 상태 미리 확인
      final prefs = await SharedPreferences.getInstance();
      final alreadyRequested = prefs.getBool('advertisement_att_requested') ?? false;

      if (alreadyRequested) {
        // 이미 요청했다면 백그라운드에서 처리
        await adProvider.initializeWithATT();
        return;
      }

      // 🔧 **명확한 ATT 권한 안내 다이얼로그 표시**
      final shouldRequest = await _showATTPermissionDialog();

      if (shouldRequest) {
        // 사용자가 동의했을 때만 ATT 권한 요청
        await adProvider.initializeWithATT();
      } else {
        // 사용자가 거부했을 때도 비개인화 광고용으로 초기화
        await adProvider.initializeWithoutATT();
      }

      debugPrint('✅ ATT 권한 명확한 요청 완료');
    } catch (e) {
      debugPrint('❌ ATT 권한 명확한 요청 오류: $e');
      // 실패해도 계속 진행
    }
  }

// 🔧 **새로운 메서드: ATT 권한 안내 다이얼로그**
  Future<bool> _showATTPermissionDialog() async {
    if (!mounted) return false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 반드시 선택하도록
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip,
              color: Theme.of(context).primaryColor,
              size: 24.r,
            ),
            SizedBox(width: 8.w),
            Text(
              '개인정보 보호 안내',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '맞춤형 광고 제공 안내',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '• 더 나은 광고 경험을 위해 앱 간 추적 권한을 요청합니다\n'
                  '• 동의 시 귀하의 광고 식별자가 광고 서비스에 전송됩니다\n'
                  '• 거부하셔도 앱 사용에는 제한이 없습니다\n'
                  '• 언제든지 iOS 설정에서 변경 가능합니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '이어서 iOS 시스템 권한 요청 화면이 표시됩니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '거부',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              '동의하고 계속',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  // 🔧 푸시 메시지 체크 개선
  Future<void> _checkPushMessages() async {
    try {
      // 앱이 종료된 상태에서 알림으로 실행된 경우
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 초기 푸시 메시지 감지: ${initialMessage.messageId}');
        await _handleFirebaseMessage(initialMessage);
      }

      // 백그라운드에서 알림 클릭으로 앱이 열린 경우
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 백그라운드 푸시 메시지 클릭: ${message.messageId}');
        _handleFirebaseMessage(message);
      });

    } catch (e) {
      debugPrint('❌ 푸시 메시지 체크 오류: $e');
    }
  }

  // 🔧 Firebase 메시지 처리 통합
  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      debugPrint('📱 Firebase 메시지 데이터: $data');

      if (data.isEmpty) {
        debugPrint('⚠️ 메시지 데이터가 비어있음');
        return;
      }

      final routing = data['routing'] as String?;
      final notificationIdStr = data['notificationId'] as String?;

      if (routing == null || routing.isEmpty) {
        debugPrint('⚠️ 라우팅 정보가 없음');
        return;
      }

      final notificationId = notificationIdStr != null ? int.tryParse(notificationIdStr) : null;

      debugPrint('🧭 Firebase 메시지 라우팅: $routing');
      if (notificationId != null) {
        debugPrint('📱 알림 ID: $notificationId');
      }

      // 앱이 초기화되지 않았으면 대기
      if (!_isInitialized) {
        debugPrint('앱 초기화 대기 중, Firebase 메시지 라우팅 보류');
        _pendingRoute = routing;
        _pendingNotificationId = notificationId;
        return;
      }

      // 즉시 라우팅 실행
      await _navigateToRouteWithNotification(routing, notificationId);

    } catch (e) {
      debugPrint('❌ Firebase 메시지 처리 오류: $e');
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      debugPrint('🔗 딥링크 초기화 시작');

      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('초기 딥링크 감지: $initialUri');
        await _handleDeepLink(initialUri);
      }

      _appLinks.uriLinkStream.listen(
              (uri) async {
            debugPrint('런타임 딥링크 감지: $uri');
            await _handleDeepLink(uri);
          },
          onError: (err) {
            debugPrint('❌ 딥링크 스트림 오류: $err');
          }
      );

      debugPrint('✅ 딥링크 초기화 완료');
    } catch (e) {
      debugPrint('❌ 딥링크 초기화 오류: $e');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      debugPrint('🔗 딥링크 처리 시작: $uri');

      final params = uri.queryParameters;
      final routing = params['routing'];
      final notificationIdStr = params['notificationId'];

      if (routing == null || routing.isEmpty) {
        debugPrint('⚠️ 딥링크에 라우팅 정보가 없습니다');
        return;
      }

      debugPrint('🧭 딥링크 라우팅: $routing');

      final notificationId = notificationIdStr != null ? int.tryParse(notificationIdStr) : null;
      if (notificationId != null) {
        debugPrint('📱 딥링크 알림 ID: $notificationId');
      }

      if (!_isInitialized) {
        debugPrint('앱 초기화 대기 중, 딥링크 라우팅 보류');
        _pendingRoute = routing;
        _pendingNotificationId = notificationId;
        return;
      }

      await _navigateToRouteWithNotification(routing, notificationId);

    } catch (e) {
      debugPrint('❌ 딥링크 처리 오류: $e');
    }
  }

  // 🔧 알림 읽음 처리를 포함한 안전한 라우팅 처리 개선
  Future<void> _navigateToRouteWithNotification(String routing, int? notificationId) async {
    try {
      if (!mounted) return;

      debugPrint('🧭 라우팅 실행 시작: $routing');
      if (notificationId != null) {
        debugPrint('📱 알림 읽음 처리 시작: $notificationId');
      }

      // 🔧 알림 읽음 처리 (동기적으로 처리)
      if (notificationId != null) {
        try {
          await notificationProvider.markNotificationAsReadFromPush(notificationId);
          debugPrint('✅ 알림 읽음 처리 완료: $notificationId');
        } catch (e) {
          debugPrint('❌ 알림 읽음 처리 오류: $e');
        }
      }

      if (!mounted) return;

      // 🔧 라우팅 처리 개선 - 더 안정적인 네비게이션
      await _executeNavigation(routing);

      debugPrint('✅ 라우팅 실행 완료: $routing');

      // 🔧 라우팅 후 관련 데이터 새로고침
      await _refreshDataAfterNavigation(routing);

    } catch (e) {
      debugPrint('❌ 라우팅 실행 오류: $e');
      if (mounted) {
        _safeFallbackToHome();
      }
    }
  }

  // 🔧 더 안정적인 네비게이션 실행
  Future<void> _executeNavigation(String routing) async {
    try {
      if (!mounted) return;

      final router = GoRouter.of(context);
      final currentPath = router.state.uri.toString();

      debugPrint('현재 경로: $currentPath, 타겟 경로: $routing');

      // 동일한 경로면 skip
      if (currentPath == routing) {
        debugPrint('동일한 경로이므로 네비게이션 생략');
        return;
      }

      // 🔧 더 안전한 네비게이션 로직
      if (_needsHomeNavigation(currentPath)) {
        debugPrint('홈으로 이동 후 타겟 라우팅');
        context.go('/my');
        context.read<HomeProvider>().setMenu(0);
        await Future.delayed(Duration(milliseconds: 200)); // 약간 더 긴 지연
      }

      if (!mounted) return;

      // 타겟 라우팅 실행
      debugPrint('타겟 라우팅 실행: $routing');
      context.push(routing);

      // 🔧 네비게이션 후 약간의 지연
      await Future.delayed(Duration(milliseconds: 100));

    } catch (e) {
      debugPrint('❌ 네비게이션 실행 오류: $e');
      _safeFallbackToHome();
    }
  }

  // 🔧 홈 네비게이션이 필요한지 판단
  bool _needsHomeNavigation(String currentPath) {
    return currentPath != '/my' &&
        currentPath != '/quick-chat' &&
        currentPath != '/more' &&
        !currentPath.startsWith('/my/') &&
        !currentPath.startsWith('/quick-chat/') &&
        !currentPath.startsWith('/more/');
  }

  // 🔧 라우팅 후 관련 데이터 새로고침 (개선된 Provider 사용)
  Future<void> _refreshDataAfterNavigation(String routing) async {
    try {
      if (!mounted) return;

      // 채팅방 라우팅인 경우
      if (routing.contains('/room/')) {
        final roomIdMatch = RegExp(r'/room/(\d+)').firstMatch(routing);
        if (roomIdMatch != null) {
          final roomId = int.parse(roomIdMatch.group(1)!);
          await _refreshRoomData(roomId);
        }
      }
      // 스케줄 라우팅인 경우
      else if (routing.contains('/schedule/')) {
        final scheduleIdMatch = RegExp(r'/schedule/(\d+)').firstMatch(routing);
        if (scheduleIdMatch != null) {
          final scheduleId = int.parse(scheduleIdMatch.group(1)!);
          await _refreshScheduleData(scheduleId);
        }
      }

    } catch (e) {
      debugPrint('❌ 라우팅 후 데이터 새로고침 오류: $e');
    }
  }

  // 🔧 방 데이터 새로고침 (개선된 Provider 사용)
  Future<void> _refreshRoomData(int roomId) async {
    try {
      if (!mounted) return;

      final chatProvider = context.read<ChatProvider>();
      final roomsProvider = context.read<RoomsProvider>();

      // 방 정보 업데이트
      await roomsProvider.updateRoom(roomId);

      // 채팅 데이터 새로고침
      if (!chatProvider.isJoined(roomId)) {
        await chatProvider.joinRoom(roomId);
      } else {
        await chatProvider.refreshRoomData(roomId);
      }

      debugPrint('✅ 방 데이터 새로고침 완료: $roomId');
    } catch (e) {
      debugPrint('❌ 방 데이터 새로고침 오류: $e');
    }
  }

  // 🔧 스케줄 데이터 새로고침
  Future<void> _refreshScheduleData(int scheduleId) async {
    try {
      if (!mounted) return;

      final userProvider = context.read<UserProvider>();
      await userProvider.fetchMySchedules(DateTime.now());

      debugPrint('✅ 스케줄 데이터 새로고침 완료: $scheduleId');
    } catch (e) {
      debugPrint('❌ 스케줄 데이터 새로고침 오료: $e');
    }
  }

  void _safeFallbackToHome() {
    try {
      if (mounted) {
        context.go('/my');
        context.read<HomeProvider>().setMenu(0);
        debugPrint('🏠 홈으로 fallback 완료');
      }
    } catch (e) {
      debugPrint('❌ 홈 이동 fallback 오류: $e');
    }
  }

  // 🔧 대기 중인 라우팅 처리 개선
  void _processPendingRoute() {
    if (_pendingRoute != null && _isInitialized) {
      debugPrint('📝 대기 중인 라우팅 처리: $_pendingRoute');
      final route = _pendingRoute!;
      final notificationId = _pendingNotificationId;

      _pendingRoute = null;
      _pendingNotificationId = null;

      // 🔧 충분한 지연 후 처리
      Future.delayed(Duration(milliseconds: 800), () async {
        if (mounted) {
          await _navigateToRouteWithNotification(route, notificationId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationProvider, HomeProvider>(
      builder: (context, notifProvider, homeProvider, child) {
        notificationProvider = notifProvider;
        this.homeProvider = homeProvider;

        return Scaffold(
            body: widget.child,
            bottomNavigationBar: NadalBottomNav(
                currentIndex: homeProvider.currentTab,
                onTap: (tab) {
                  homeProvider.onChangedTab(tab);
                  if (tab == 0) {
                    context.go('/my');
                  } else if (tab == 1) {
                    context.go('/quick-chat');
                  } else if (tab == 2) {
                    context.go('/more');
                  }
                }
            )
        );
      },
    );
  }
}