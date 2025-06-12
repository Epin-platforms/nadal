import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  static const Duration _initTimeout = Duration(seconds: 30); // 초기화 타임아웃

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

  // 앱 초기화 프로세스 순차 실행
  void _initializeApp() async {
    if (_isInitializing) return;

    try {
      _isInitializing = true;
      print('🚀 앱 초기화 시작');

      // 🔧 타임아웃 설정
      _initTimeoutTimer = Timer(_initTimeout, () {
        if (!_isInitialized) {
          print('⏰ 초기화 타임아웃 - 강제 완료');
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

      print('✅ 앱 초기화 완료');
    } catch (e) {
      print('❌ 앱 초기화 오류: $e');
      _forceInitializationComplete();
    } finally {
      _initTimeoutTimer?.cancel();
      _isInitializing = false;
    }
  }

  // 🔧 강제 초기화 완료
  void _forceInitializationComplete() {
    _isInitialized = true;
    _processPendingRoute();
    print('⚠️ 초기화 강제 완료됨');
  }

  Future<void> _setCommunity() async {
    if (!mounted) return;

    try {
      final roomsProvider = context.read<RoomsProvider>();
      final chatProvider = context.read<ChatProvider>();
      final userProvider = context.read<UserProvider>();

      print('1단계: 방 목록 초기화 시작');
      await roomsProvider.roomInitialize();
      if (!mounted) return;
      print('1단계 완료: 방 목록 로드됨');

      print('2단계: 소켓 및 채팅 초기화 시작');
      await chatProvider.initializeSocket();
      if (!mounted) return;

      print('3단계: 사용자 일정 초기화 시작');
      // 🔧 일정 초기화는 백그라운드에서 처리 (필수가 아님)
      _loadSchedulesInBackground(userProvider);
      if (!mounted) return;

      print('✅ 커뮤니티 초기화 완료');
    } catch (e) {
      print('❌ 커뮤니티 초기화 오류: $e');
      // 커뮤니티 초기화 실패해도 앱은 계속 실행
    }
  }

  // 🔧 백그라운드에서 일정 로드
  void _loadSchedulesInBackground(UserProvider userProvider) {
    Future.microtask(() async {
      try {
        await userProvider.fetchMySchedules(DateTime.now());
        print('✅ 백그라운드 일정 로드 완료');
      } catch (e) {
        print('❌ 백그라운드 일정 로드 오류: $e');
      }
    });
  }

  Future<void> _initStep() async {
    if (!mounted) return;

    try {
      // 알림 초기화 (백그라운드에서)
      _initNotificationInBackground();

      // 권한 체크 (백그라운드에서)
      _checkPermissionsInBackground();

      // 푸시메시지 체크
      _checkPush();

      _isInitialized = true;
      print('✅ 앱 초기화 단계 완료');
    } catch (e) {
      print('❌ 초기화 단계 오류: $e');
      _isInitialized = true; // 에러가 있어도 앱은 계속 실행
    }
  }

  // 🔧 백그라운드에서 알림 초기화
  void _initNotificationInBackground() {
    Future.microtask(() async {
      try {
        await notificationProvider.initialize();
        print('✅ 백그라운드 알림 초기화 완료');
      } catch (e) {
        print('❌ 백그라운드 알림 초기화 오류: $e');
      }
    });
  }

  // 🔧 백그라운드에서 권한 체크
  void _checkPermissionsInBackground() {
    Future.microtask(() async {
      try {
        if (mounted) {
          await PermissionManager.checkAndShowPermissions(context);
          print('✅ 백그라운드 권한 체크 완료');
        }
      } catch (e) {
        print('❌ 백그라운드 권한 체크 오류: $e');
      }
    });
  }

  void _checkPush() {
    try {
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null && msg.data['routing'] != null) {
          print('푸시 메시지 라우팅: ${msg.data['routing']}');

          // 알림 ID 추출
          final notificationIdStr = msg.data['notificationId'] as String?;
          final notificationId = notificationIdStr != null ? int.tryParse(notificationIdStr) : null;

          Future.microtask(() {
            _navigateToRouteWithNotification(msg.data['routing']!, notificationId);
          });
        }
      });
    } catch (e) {
      print('❌ 푸시 메시지 체크 오류: $e');
    }
  }

  // 딥링크 초기화
  Future<void> _initDeepLinks() async {
    try {
      print('🔗 딥링크 초기화 시작');

      // 초기 링크 처리
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('초기 딥링크 감지: $initialUri');
        await _handleDeepLink(initialUri);
      }

      // 런타임 링크 처리
      _appLinks.uriLinkStream.listen(
              (uri) async {
            print('런타임 딥링크 감지: $uri');
            await _handleDeepLink(uri);
          },
          onError: (err) {
            print('❌ 딥링크 스트림 오류: $err');
          }
      );

      print('✅ 딥링크 초기화 완료');
    } catch (e) {
      print('❌ 딥링크 초기화 오류: $e');
    }
  }

  // 딥링크 처리 로직
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      print('🔗 딥링크 처리 시작: $uri');

      final params = uri.queryParameters;
      final routing = params['routing'];
      final notificationIdStr = params['notificationId'];

      if (routing == null || routing.isEmpty) {
        print('⚠️ 라우팅 정보가 없습니다');
        return;
      }

      print('추출된 라우팅: $routing');

      final notificationId = notificationIdStr != null ? int.tryParse(notificationIdStr) : null;
      if (notificationId != null) {
        print('추출된 알림 ID: $notificationId');
      }

      // 앱이 초기화되지 않았으면 대기
      if (!_isInitialized) {
        print('앱 초기화 대기 중, 라우팅 보류: $routing');
        _pendingRoute = routing;
        _pendingNotificationId = notificationId;
        return;
      }

      // 즉시 라우팅 실행
      await _navigateToRouteWithNotification(routing, notificationId);

    } catch (e) {
      print('❌ 딥링크 처리 오류: $e');
    }
  }

  // 알림 읽음 처리를 포함한 안전한 라우팅 처리
  Future<void> _navigateToRouteWithNotification(String routing, int? notificationId) async {
    try {
      if (!mounted) return;

      print('🧭 라우팅 실행 시작: $routing');
      if (notificationId != null) {
        print('📱 알림 읽음 처리 시작: $notificationId');
      }

      // 알림 읽음 처리 (백그라운드에서)
      if (notificationId != null) {
        Future.microtask(() async {
          try {
            await notificationProvider.markNotificationAsReadFromPush(notificationId);
            print('✅ 알림 읽음 처리 완료: $notificationId');
          } catch (e) {
            print('❌ 알림 읽음 처리 오류: $e');
          }
        });
      }

      if (!mounted) return;

      // 🔧 라우팅 처리 개선
      await _safeNavigate(routing);

      print('✅ 라우팅 실행 완료: $routing');

    } catch (e) {
      print('❌ 라우팅 실행 오류: $e');
      // 오류 시 홈으로 fallback
      if (mounted) {
        _safeFallbackToHome();
      }
    }
  }

  // 🔧 안전한 네비게이션
  Future<void> _safeNavigate(String routing) async {
    try {
      if (!mounted) return;

      // 현재 경로 확인
      final router = GoRouter.of(context);
      final currentPath = router.state.uri.toString();

      // 동일한 경로면 skip
      if (currentPath == routing) {
        print('동일한 경로이므로 네비게이션 생략: $routing');
        return;
      }

      // 홈으로 이동 후 잠시 대기
      if (currentPath != '/my' && currentPath != '/quick-chat' && currentPath != '/more') {
        context.go('/my');
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!mounted) return;

      // 타겟 라우팅 실행
      context.push(routing);

    } catch (e) {
      print('❌ 안전한 네비게이션 오류: $e');
      _safeFallbackToHome();
    }
  }

  // 🔧 안전한 홈 이동
  void _safeFallbackToHome() {
    try {
      if (mounted) {
        context.go('/my');
      }
    } catch (e) {
      print('❌ 홈 이동 fallback 오류: $e');
    }
  }

  // 대기 중인 라우팅 처리
  void _processPendingRoute() {
    if (_pendingRoute != null && _isInitialized) {
      print('📝 대기 중인 라우팅 처리: $_pendingRoute');
      final route = _pendingRoute!;
      final notificationId = _pendingNotificationId;

      _pendingRoute = null;
      _pendingNotificationId = null;

      // 🔧 약간의 지연 후 처리
      Future.delayed(const Duration(milliseconds: 500), () async {
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
                  } else if(tab == 1){
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