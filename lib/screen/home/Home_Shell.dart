import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_sports_calendar/screen/home/Nadal_BottomNav.dart';

import '../../manager/permission/Permission_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../provider/notification/Notification_Provider.dart';

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
      debugPrint('🚀 앱 초기화 시작');

      _initTimeoutTimer = Timer(_initTimeout, () {
        if (!_isInitialized) {
          debugPrint('⏰ 초기화 타임아웃 - 강제 완료');
          _forceInitializationComplete();
        }
      });

      // 1. 딥링크 초기화 (가장 먼저)
      await _initDeepLinks();

      // 2. 커뮤니티 설정
      await _setCommunity();

      // 3. 기타 초기화
      await _initStep();

      // 4. 초기화 완료 후 대기 중인 라우팅 처리
      _processPendingRoute();

      debugPrint('✅ 앱 초기화 완료');
    } catch (e) {
      debugPrint('❌ 앱 초기화 오류: $e');
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

  Future<void> _setCommunity() async {
    if (!mounted) return;

    try {
      final roomsProvider = context.read<RoomsProvider>();
      final chatProvider = context.read<ChatProvider>();
      final userProvider = context.read<UserProvider>();

      debugPrint('1단계: 방 목록 초기화 시작');
      await roomsProvider.roomInitialize();
      if (!mounted) return;
      debugPrint('1단계 완료: 방 목록 로드됨');

      debugPrint('2단계: 소켓 및 채팅 초기화 시작');
      await chatProvider.initializeSocket();
      if (!mounted) return;

      debugPrint('3단계: 사용자 일정 초기화 시작');
      _loadSchedulesInBackground(userProvider);
      if (!mounted) return;

      debugPrint('✅ 커뮤니티 초기화 완료');
    } catch (e) {
      debugPrint('❌ 커뮤니티 초기화 오류: $e');
    }
  }

  void _loadSchedulesInBackground(UserProvider userProvider) {
    Future.microtask(() async {
      try {
        await userProvider.fetchMySchedules(DateTime.now());
        debugPrint('✅ 백그라운드 일정 로드 완료');
      } catch (e) {
        debugPrint('❌ 백그라운드 일정 로드 오류: $e');
      }
    });
  }

  Future<void> _initStep() async {
    if (!mounted) return;

    try {
      // 🔧 알림 초기화를 먼저 완료 (라우팅 처리를 위해)
      await _initNotification();

      // 권한 체크 (백그라운드에서)
      _checkPermissionsInBackground();

      // 🔧 푸시메시지 체크 개선
      await _checkPushMessages();

      _isInitialized = true;
      debugPrint('✅ 앱 초기화 단계 완료');
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

  void _checkPermissionsInBackground() {
    Future.microtask(() async {
      try {
        if (mounted) {
          await PermissionManager.checkAndShowPermissions(context);
          debugPrint('✅ 백그라운드 권한 체크 완료');
        }
      } catch (e) {
        debugPrint('❌ 백그라운드 권한 체크 오류: $e');
      }
    });
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

  // 🔧 라우팅 후 관련 데이터 새로고침
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

  // 🔧 방 데이터 새로고침
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
      debugPrint('❌ 스케줄 데이터 새로고침 오류: $e');
    }
  }

  void _safeFallbackToHome() {
    try {
      if (mounted) {
        context.go('/my');
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