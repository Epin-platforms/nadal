import 'package:my_sports_calendar/model/report/Report_Model.dart';
import 'package:my_sports_calendar/provider/profile/User_Profile_Provider.dart';
import 'package:my_sports_calendar/screen/account/Account_Edit.dart';
import 'package:my_sports_calendar/screen/auth/cancel/Cancel_User.dart';
import 'package:my_sports_calendar/screen/friends/Friend_List_Page.dart';
import 'package:my_sports_calendar/screen/image/Image_View.dart';
import 'package:my_sports_calendar/screen/notification/Notification_Page.dart';
import 'package:my_sports_calendar/screen/profile/User_Profile.dart';
import 'package:my_sports_calendar/screen/qna/Qna_List.dart';
import 'package:my_sports_calendar/screen/qna/Qna_Write.dart';
import 'package:my_sports_calendar/screen/quick_chat/Quick_Chat_Main.dart';
import 'package:my_sports_calendar/screen/report/Report_Page.dart';
import 'package:my_sports_calendar/screen/schedule/Schedule.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/kdk/KDK_Real_Time_Result.dart';
import 'package:my_sports_calendar/screen/web/Nadal_WebView.dart';
import 'package:url_launcher/url_launcher.dart';

import '../manager/project/Import_Manager.dart';
import '../provider/room/Room_Provider.dart';
import '../screen/account/Account_Select.dart';
import '../screen/auth/Login_Page.dart';
import '../screen/auth/Register_Page.dart';
import '../screen/home/Home_Shell.dart';
import '../screen/league/League_Page.dart';
import '../screen/my/Main_Page.dart';
import '../screen/profile/Affiliation_Edit.dart';
import '../screen/profile/Kakao_Connect.dart';
import '../screen/profile/My_Profile.dart';
import '../screen/profile/Profile_Edit.dart';
import '../screen/profile/Profile_More.dart';
import '../screen/rooms/create/Create_Room.dart';
import '../screen/splash/Splash_Page.dart';

Future<void> launchWebPage(String url) async {
  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

class AppRoute{
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
      observers: [
        routeObserver
      ],
      navigatorKey: navigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NadalTransitionPage(
            child: SplashPage(),
            key: state.pageKey,
          )
        ),
        GoRoute(
            path: '/loading',
            pageBuilder: (context, state) => CustomTransitionPage(
                opaque: false,
                fullscreenDialog: true,
                key: state.pageKey,
                child: LoadingBlock(),
                barrierColor: Colors.black.withValues(alpha: 0.4),
                barrierDismissible: false,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
              },
            )
        ),
        ShellRoute(
            builder: (context, state, child){
              return HomeShell(child: child); // 바텀 네비게이션을 포함한 Shell
            },
          routes: [
            GoRoute(
              path: '/my',
                pageBuilder: (context, state) => NadalTransitionPage(
                  child: MainPage(homeProvider: Provider.of<HomeProvider>(context),),
                  key: state.pageKey,
                    transitionType: PageTransitionType.fade
                ),
            ),
            GoRoute(
                path: '/quick-chat',
                pageBuilder: (context, state) => NadalTransitionPage(
                    child: QuickChatMain(),
                    key: state.pageKey,
                    transitionType: PageTransitionType.fade
                )
            ),
            GoRoute(
              path: '/more',
                pageBuilder: (context, state) => NadalTransitionPage(
                  child: MorePage(),
                  key: state.pageKey,
                  transitionType: PageTransitionType.fade
                )
            ),
          ],
        ),
        GoRoute(
            path: '/league',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: LeaguePage(),
                key: state.pageKey,
                transitionType: PageTransitionType.fade
            )
        ),
        GoRoute(
            path: '/myProfile',
            builder: (context, state) => const MyProfile(),
        ),
        GoRoute(
            path: '/profileEdit',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: ProfileEdit(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromBottom
            )
        ),
        GoRoute(
            path: '/affiliationEdit',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: AffiliationEdit(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromBottom
            )
        ),
        GoRoute(
            path: '/kakaoConnect',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: KakaoConnect(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromBottom
            )
        ),
        GoRoute(
            path: '/profileMore',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: ProfileMore(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromBottom
            )
        ),
        GoRoute(
            path: '/createRoom',
            pageBuilder: (context, state){
              final bool isOpen = state.uri.queryParameters['isOpen'] == 'TRUE';
              return NadalTransitionPage(
                  child: CreateRoom(isOpen: isOpen,),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromBottom
              );
            }
        ),
        GoRoute(
            path: '/searchRoom',
            pageBuilder: (context, state){
              final bool isOpen = state.uri.queryParameters['isOpen'] == 'TRUE';
              return NadalTransitionPage(
                  child: SearchRoom(isOpen : isOpen),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromRight
              );
            }
        ),
        GoRoute(
            path: '/previewRoom/:roomId',
            pageBuilder: (context, state){
              final roomId = state.pathParameters['roomId']!;
              return NadalTransitionPage(
                  child: ChangeNotifierProvider(
                    create: (_)=> RoomPreviewProvider(roomId),
                    child: RoomPreview(),
                  ),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromRight
              );
            }
        ),
        //방 라우팅
        ShellRoute(
            builder: (context, state, child){
              return ChangeNotifierProvider(
                create: (_) => RoomProvider(),
                child: child,
              );
            },
            routes: [
              GoRoute(
                  path: '/room/:roomId',
                  pageBuilder: (context, state){
                    final int roomId = int.parse(state.pathParameters['roomId'] ?? '-1');
                    return NadalTransitionPage(
                        child: Room(roomId: roomId),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  },
              ),
              GoRoute(
                  path: '/room/:roomId/information',
                  pageBuilder: (context, state){
                    final int roomId = int.parse(state.pathParameters['roomId'] ?? '-1');
                    return NadalTransitionPage(
                        child: RoomDrawer(roomId: roomId,),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromBottom
                    );
                  }
              ),
              GoRoute(
                  path: '/room/:roomId/editRoom',
                  pageBuilder: (context, state){
                    return NadalTransitionPage(
                        child: RoomEdit(),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  }
              ),
              GoRoute(
                  path: '/room/:roomId/editMember',
                  pageBuilder: (context, state){
                    return NadalTransitionPage(
                        child: MemberEdit(),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  }
              ),
              GoRoute(
                  path: '/room/:roomId/schedule',
                  pageBuilder: (context, state){
                    final int roomId = int.parse(state.pathParameters['roomId'] ?? '-1');
                    return NadalTransitionPage(
                        child: ChangeNotifierProvider(
                          create: (_)=> RoomScheduleProvider(roomId),
                          child: RoomSchedule(roomId: roomId,),
                        ),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  }
              ),

            ]
        ),
        //친구관련
        GoRoute(
            path: '/friends',
            pageBuilder: (context, state){
              final bool selectable = state.uri.queryParameters['selectable'] == 'true' ? true : false;
              return NadalTransitionPage(
                child: FriendListPage(selectable: selectable),
                key: state.pageKey,
              );
            }
        ),
        GoRoute(
            path: '/search/friends',
            pageBuilder: (context, state) => NadalTransitionPage(
              child: FriendsSearch(),
              key: state.pageKey,
            )
        ),
        //스케줄 생성
        GoRoute(
            path: '/create/schedule',
            pageBuilder: (context, state) => NadalTransitionPage(
              child: ScheduleCreate(),
              key: state.pageKey,
              transitionType: PageTransitionType.slideFromBottom
            )
        ),
        //스케줄 메인페이지
        ShellRoute(
          builder: (context, state, child){
            return  MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_)=> ScheduleProvider()),
                  ChangeNotifierProvider(create: (_)=> CommentProvider()),
                ],
                child: child,
            );
          },
          routes: [
          GoRoute(
              path: '/schedule/:scheduleId',
              pageBuilder: (context, state){
                final rawId = state.pathParameters['scheduleId'];
                final scheduleId = int.parse(rawId ?? '-1');

                return NadalTransitionPage(
                    child: Schedule(scheduleId: scheduleId),
                    key: state.pageKey,
                    transitionType: PageTransitionType.slideFromRight
                );
              }
            ),
            GoRoute(
                path: '/schedule/:scheduleId/participation',
                pageBuilder: (context, state) => NadalTransitionPage(
                    child: ScheduleParticipationList(),
                    key: state.pageKey,
                    transitionType: PageTransitionType.slideFromBottom
                )
            ),
            GoRoute(
                path: '/schedule/:scheduleId/edit',
                pageBuilder: (context, state) => NadalTransitionPage(
                    child: ScheduleEditPage(),
                    key: state.pageKey,
                    transitionType: PageTransitionType.slideFromBottom
                )
            ),
            GoRoute(
                path: '/live-match-view',
                pageBuilder: (context, state) => NadalTransitionPage(
                    child: KdkRealTimeResult(),
                    key: state.pageKey,
                    transitionType: PageTransitionType.slideFromBottom
                )
            ),
        ]),

        //계좌페이지
        ShellRoute(
            builder: (context, state, child){
              return ChangeNotifierProvider(
                create: (_) => AccountProvider(),
                child: child,
              );
            },
            routes: [
              //계좌선택
              GoRoute(
                  path: '/select/account',
                  pageBuilder: (context, state){
                    final bool selectable = state.uri.queryParameters['selectable'] == 'false' ? false : true;
                    return NadalTransitionPage(
                        child: AccountSelect(selectable: selectable),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  }
              ),
              //계좌만들기
              GoRoute(
                  path: '/create/account',
                  pageBuilder: (context, state) => NadalTransitionPage(
                      child: AccountCreate(),
                      key: state.pageKey,
                      transitionType: PageTransitionType.slideFromRight
                  )
              ),
              GoRoute(
                  path: '/update/account',
                  pageBuilder: (context, state){
                    final int accountId = int.parse(state.uri.queryParameters['accountId'] ?? '-1');
                    return NadalTransitionPage(
                        child: AccountEdit(accountId: accountId,),
                        key: state.pageKey,
                        transitionType: PageTransitionType.slideFromRight
                    );
                  }
              ),
            ]),
        //이미지 보가
        GoRoute(
            path: '/image',
            pageBuilder: (context, state){
              final url = state.uri.queryParameters['url']!;
              return  NadalTransitionPage(
                child: ImageView(imageUrl: url),
                transitionType: PageTransitionType.slideFromRight,
                key: state.pageKey,
              );
            }
        ),
        //사용자 프로필
        GoRoute(
            path: '/user/:uid',
            pageBuilder: (context, state){
              final uid = state.pathParameters['uid'];
              return  NadalTransitionPage(
                child: ChangeNotifierProvider(
                  create: (_)=> UserProfileProvider(uid),
                  child: UserProfile(),
                ),
                key: state.pageKey,
              );
            }
        ),
        //알림 페이지
        GoRoute(
            path: '/notification',
            pageBuilder: (context, state) => NadalTransitionPage(
              child: NotificationPage(),
              key: state.pageKey,
            )
        ),
        //로그인 페이지
        GoRoute(
          path: '/login',
            pageBuilder: (context, state){
              final reset = state.uri.queryParameters['reset'] == 'true' ? true : false;
              return NadalTransitionPage(
                child: LoginPage(reset: reset),
                key: state.pageKey,
              );
            }
        ),
        GoRoute(
          path: '/register',
            pageBuilder: (context, state) => NadalTransitionPage(
              child: ChangeNotifierProvider(
                create: (_)=> RegisterProvider(),
                child: RegisterPage()
              ),
              key: state.pageKey,
              transitionType: PageTransitionType.slideFromRight
            )
        ),

        GoRoute(
            path: '/qna',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: QnaList(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromRight
            )
        ),
        GoRoute(
            path: '/qna/write',
            pageBuilder: (context, state) => NadalTransitionPage(
                child: QnaWrite(),
                key: state.pageKey,
                transitionType: PageTransitionType.slideFromRight
            )
        ),

        GoRoute(
            path: '/report',
            pageBuilder: (context, state){
              final targetId = state.uri.queryParameters['targetId'] ?? 'null';
              final type = ReportModel.switchToType(state.uri.queryParameters['type']);
              return NadalTransitionPage(
                  child: ReportPage(targetId: targetId, type: type,),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromRight
              );
            }
        ),

        //웹뷰
        GoRoute(
            path: '/web',
            pageBuilder: (context, state){
              final url = state.uri.queryParameters['url'];
              return NadalTransitionPage(
                  child: NadalWebView(url: url),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromRight
              );
            }
        ),

        //회원탈퇴
        GoRoute(
            path: '/cancel',
            pageBuilder: (context, state){
              return NadalTransitionPage(
                  child: CancelUser(),
                  key: state.pageKey,
                  transitionType: PageTransitionType.slideFromRight
              );
            }
        ),

      ],
    errorBuilder: (context, state) => Scaffold(
      appBar: NadalAppbar(),
      body: Center(child: Text('Page Not Found: ${state.error}')),
    ),
    debugLogDiagnostics: true, // 디버깅용 로그 출력
  );

  static void pushLoading(){
    final ctx = navigatorKey.currentContext;

    if(ctx != null){
      final path = GoRouter.of(ctx).state.uri.toString(); // state.path는 nullable
      if (!path.contains('/loading') && !path.contains('/splash')) {
        GoRouter.of(ctx).push('/loading');
      }
    }
  }

  static void popLoading(){
    final ctx = navigatorKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      final location = GoRouter.of(ctx).state.uri.toString();
      if (location == '/loading') {
        GoRouter.of(ctx).pop();
      }
    }
  }

  static BuildContext? get context => navigatorKey.currentContext;

  /// 현재 location (경로)
  static String? get location {
    final ctx = context;
    if (ctx != null) {
      return GoRouter.of(ctx).state.path;
    }
    return null;
  }

}