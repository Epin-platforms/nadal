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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // 앱 초기화 프로세스 순차 실행
  void _initializeApp() async {
    try {
      print('🚀 앱 초기화 시작');

      // 1. 커뮤니티 설정
      await _setCommunity();

      // 2. 딥링크 초기화
      await _initDeepLinks();

      // 3. 기타 초기화
      await _initStep();

      // 4. 초기화 완료 후 대기 중인 라우팅 처리
      _processPendingRoute();

      print('✅ 앱 초기화 완료');
    } catch (e) {
      print('❌ 앱 초기화 오류: $e');
    }
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
      await userProvider.fetchMySchedules(DateTime.now());
      if (!mounted) return;
      print('3단계 완료: 일정 로드됨');

      print('✅ 커뮤니티 초기화 완료');
    } catch (e) {
      print('❌ 커뮤니티 초기화 오류: $e');
    }
  }

  Future<void> _initStep() async {
    if (!mounted) return;

    try {
      // 알림 초기화
      notificationProvider.initialize();

      // 권한 체크
      await _checkPermissions();

      // 푸시메시지 체크
      _checkPush();

      _isInitialized = true;
      print('✅ 앱 초기화 단계 완료');
    } catch (e) {
      print('❌ 초기화 단계 오류: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      if (mounted) {
        await PermissionManager.checkAndShowPermissions(context);
      }
    } catch (e) {
      print('❌ 권한 체크 오류: $e');
    }
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

      // 알림 읽음 처리
      if (notificationId != null) {
        try {
          await notificationProvider.markNotificationAsReadFromPush(notificationId);
          print('✅ 알림 읽음 처리 완료: $notificationId');
        } catch (e) {
          print('❌ 알림 읽음 처리 오류: $e');
        }
      }

      if (!mounted) return;

      // 홈으로 이동 후 잠시 대기
      context.go('/my');
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // 타겟 라우팅 실행
      context.push(routing);

      print('✅ 라우팅 실행 완료: $routing');

    } catch (e) {
      print('❌ 라우팅 실행 오류: $e');
      // 오류 시 홈으로 fallback
      if (mounted) {
        context.go('/my');
      }
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

      Future.microtask(() async {
        await _navigateToRouteWithNotification(route, notificationId);
      });
    }
  }

  @override
  void dispose() {
    // 리소스 정리
    _pendingRoute = null;
    _pendingNotificationId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    notificationProvider = Provider.of<NotificationProvider>(context);
    homeProvider = Provider.of<HomeProvider>(context);

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
  }
}