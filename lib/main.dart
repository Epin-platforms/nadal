import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_sports_calendar/provider/app/Advertisement_Provider.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'firebase_options.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'manager/project/Import_Manager.dart';

void main() async {
  // Flutter 바인딩 초기화 (가장 먼저 실행)
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // 패키지 초기화
    await asyncInitPackage();

    // 화면 세로 고정
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const RootApp());
  } catch (e) {
    print('앱 초기화 실패: $e');
    // 기본 에러 앱 실행
    runApp(const ErrorApp());
  }
}

Future<void> asyncInitPackage() async {
  try {
    // Firebase 초기화 (재시도 로직 추가)
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase 초기화 성공');
        break;
      } catch (e) {
        retryCount++;
        print('❌ Firebase 초기화 실패 (시도 $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          throw Exception('Firebase 초기화 실패: $e');
        }

        // 잠시 대기 후 재시도
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // 스크린 유틸 초기화
    await ScreenUtil.ensureScreenSize();
    print('✅ ScreenUtil 초기화 성공');

    // 날짜 형식 초기화
    await initializeDateFormatting();
    print('✅ 날짜 형식 초기화 성공');

    // 환경변수 로드
    try {
      await dotenv.load(fileName: '.env');
      print('✅ 환경변수 로드 성공');
    } catch (e) {
      print('⚠️ .env 파일 로드 실패 (선택사항): $e');
    }

    //광고 초기화
    await MobileAds.instance.initialize();
    // 카카오 SDK 초기화
    try {
      final nativeKey = dotenv.get('KAKAO_NATIVE_APP_KEY', fallback: '');
      final jsKey = dotenv.get('KAKAO_JAVASCRIPT_APP_KEY', fallback: '');

      if (nativeKey.isNotEmpty && jsKey.isNotEmpty) {
        KakaoSdk.init(
          nativeAppKey: nativeKey,
          javaScriptAppKey: jsKey,
        );
        print('✅ 카카오 SDK 초기화 성공');
      } else {
        print('⚠️ 카카오 SDK 키가 설정되지 않았습니다');
      }
    } catch (e) {
      print('⚠️ 카카오 SDK 초기화 실패: $e');
    }

  } catch (e) {
    print('❌ 패키지 초기화 실패: $e');
    rethrow;
  }
}

class AppDriver extends StatelessWidget {
  final VoidCallback onReset;

  const AppDriver({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(402.0, 874.0),
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => HomeProvider()),
            ChangeNotifierProvider(create: (_) => FriendsProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => RoomsProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider.value(value: AdManager.instance),
          ],
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
        );
      },
    );
  }
}

// 에러 발생 시 표시할 기본 앱
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                '앱 초기화 중 문제가 발생했습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '앱을 다시 시작해주세요',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  RootAppState createState() => RootAppState();
}

class RootAppState extends State<RootApp> {
  Key _key = UniqueKey();

  void resetApp() {
    setState(() {
      _key = UniqueKey(); // AppDriver 재생성
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      key: _key,
      onReset: resetApp,
    );
  }
}




//재시작을 위한 래퍼
class AppWrapper extends StatelessWidget {
  final VoidCallback onReset;

  const AppWrapper({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return AppDriver(onReset: onReset);
  }
}


