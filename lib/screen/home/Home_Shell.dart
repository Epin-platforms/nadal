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

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      setCommunity();
    });
    super.initState();
  }

  void setCommunity() async{
    final roomsProvider = context.read<RoomsProvider>();
    final chatProvider = context.read<ChatProvider>();
    final userProvider = context.read<UserProvider>();
    await roomsProvider.roomInitialize();
    chatProvider.initializeSocket(); //소켓 연결하면 자동으로 채팅 데이터 불러와줌
    userProvider.fetchMySchedules(DateTime.now()); //스케줄 init
    _initStep();
  }

  void _initStep() async{
    //알림 초기화
    notificationProvider.initialize();
    //권한 체크
    _checkPermissions();
    //마케팅 체크
    //await _marketingCheck();
    //푸쉬메시지로 접속했는지 체크
    _checkPush();
    //딥링크로 접속했는지 체크
    _initDeepLinks();
  }

  Future<void> _checkPermissions() async {
    // 홈 화면에서 권한 요청
    await PermissionManager.checkAndShowPermissions(context);
  }

  //푸시 메시지로 들어왔으면
  void _checkPush() {
    final nav =  GoRouter.of(context);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        Future.microtask(() {
          if (msg.data['routing'] != null) {
            nav.go('/my');
            nav.push(msg.data['routing']);
          }
        });
      }
    });
  }
  
  //카카오 공유하기로 접속한 경우
  Future<void> _initDeepLinks() async {
    print('딥링크 실행');
    _appLinks.getInitialLink();
    // Handle links
    // ✅ 최초 1회 딥링크 처리
    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // ✅ 이후의 링크 처리
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    final item = uri.queryParameters;

    if(item['routing'] != null){
      context.go('/my');
      context.push(item['routing']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    notificationProvider = Provider.of<NotificationProvider>(context);
    homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NadalBottomNav(currentIndex: homeProvider.currentTab, onTap: (tab){
        homeProvider.onChangedTab(tab);
        if(tab == 0){
          context.go('/my');
        }else if(tab == 1){
          context.go('/league');
        }else if(tab == 2){
          context.go('/more');
        }
      })
    );
  }
}
