import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_sports_calendar/provider/app/Advertisement_Provider.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/provider/chat/Chat_Provider.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'package:my_sports_calendar/provider/room/Rooms_Provider.dart';
import 'package:my_sports_calendar/provider/widget/Home_Provider.dart';
import 'firebase_options.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'manager/project/Import_Manager.dart';


void main()  async{
  WidgetsFlutterBinding.ensureInitialized();

  //패키지 초기화
  await asyncInitPackage();

  //화면 세로 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AppDriver());
}

Future<void> asyncInitPackage() async{
  //파이어베이스 초기화
  try {
    final json = await rootBundle.loadString('GoogleService-Info.plist');
    print('✅ GoogleService-Info.plist loaded!');
  } catch (e) {
    print('❌ GoogleService-Info.plist NOT found at runtime!');
  }

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  //스크린 초기화
  await ScreenUtil.ensureScreenSize();

  //현제위치 초기화
  await initializeDateFormatting();

  await dotenv.load(fileName: '.env');

  KakaoSdk.init(
      nativeAppKey: dotenv.get('KAKAO_NATIVE_APP_KEY'),
      javaScriptAppKey: dotenv.get('KAKAO_JAVASCRIPT_APP_KEY')
  );
}

class AppDriver extends StatelessWidget {
  const AppDriver({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(402.0, 874.0),
      builder: (context, child){
        return MultiProvider(
            builder: (context, child) {
              final provider = Provider.of<AppProvider>(context);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                themeMode: provider.themeMode,
                theme: ThemeManager.lightTheme,
                darkTheme: ThemeManager.darkTheme,
                routerConfig: AppRoute.router,
              );
            },
            providers: [
              ChangeNotifierProvider(create: (_)=> AppProvider()),
              ChangeNotifierProvider(create: (_)=> UserProvider()),
              ChangeNotifierProvider(create: (_)=> HomeProvider()),
              ChangeNotifierProvider(create: (_)=> FriendsProvider()),
              ChangeNotifierProvider(create: (_)=> ChatProvider()),
              ChangeNotifierProvider(create: (_)=> RoomsProvider()),
              ChangeNotifierProvider(create: (_)=> NotificationProvider()),
              ChangeNotifierProvider(create: (_)=> AdvertisementProvider())
            ],);
      }
    );
  }
}
