import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_sports_calendar/manager/project/ThemeMode_Manager.dart';
import 'package:my_sports_calendar/provider/app/Advertisement_Provider.dart';
import 'package:my_sports_calendar/provider/friends/Block_Provider.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'firebase_options.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'manager/project/Import_Manager.dart';

void main() async {
  // Flutter 바인딩 초기화 (가장 먼저 실행)
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 화면 세로 고정 (먼저 설정)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 패키지 초기화
    await _initializePackages();

    runApp(const RootApp());
  } catch (e) {
    debugPrint('앱 초기화 실패: $e');
    runApp(const ErrorApp());
  }
}

/// 패키지 초기화 - 순차적이고 안전한 초기화
Future<void> _initializePackages() async {
  try {
    // 1. Firebase 초기화 (재시도 로직)
    await _initializeFirebase();

    // 2. 🔧 기본 AdMob 초기화만 (ATT는 나중에)
    await _initializeBasicAds();

    // 3. 기본 패키지들 초기화
    await _initializeBasicPackages();

    // 4. 카카오 SDK 초기화 (마지막)
    await _initializeKakaoSdk();

    // 5. 테마 초기화
    await ThemeModeManager().initialize();
  } catch (e) {
    debugPrint('패키지 초기화 실패: $e');
    rethrow;
  }
}

/// Firebase 초기화 with 재시도 (기존과 동일)
Future<void> _initializeFirebase() async {
  const maxRetries = 3;
  int retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase 초기화 성공');
      return;
    } catch (e) {
      retryCount++;
      debugPrint('❌ Firebase 초기화 실패 (시도 $retryCount/$maxRetries): $e');

      if (retryCount >= maxRetries) {
        throw Exception('Firebase 초기화 최종 실패: $e');
      }

      // 잠시 대기 후 재시도
      await Future.delayed(Duration(milliseconds: 500 * retryCount));
    }
  }
}

/// 🔧 기본 AdMob 초기화만 (ATT 권한 처리 제외)
Future<void> _initializeBasicAds() async {
  try {
    debugPrint('🔧 기본 AdMob 초기화 시작 (ATT 제외)');

    // 기본 AdMob 초기화만 수행 (ATT 권한 처리는 Advertisement_Provider에서)
    final initCompleter = Completer<void>();

    MobileAds.instance.initialize().then((status) {
      if (!initCompleter.isCompleted) {
        initCompleter.complete();
        debugPrint('✅ 기본 AdMob 초기화 성공');
      }
    }).catchError((error) {
      if (!initCompleter.isCompleted) {
        initCompleter.complete();
        debugPrint('⚠️ 기본 AdMob 초기화 실패 (계속 진행): $error');
      }
    });

    // 타임아웃 설정 (5초)
    Timer(const Duration(seconds: 5), () {
      if (!initCompleter.isCompleted) {
        initCompleter.complete();
        debugPrint('⚠️ 기본 AdMob 초기화 타임아웃 (계속 진행)');
      }
    });

    // 완료될 때까지 대기
    await initCompleter.future;

  } catch (e) {
    debugPrint('⚠️ 기본 AdMob 초기화 오류 (계속 진행): $e');
    // 광고 초기화 실패해도 앱은 계속 실행
  }
}

/// 기본 패키지 초기화 (기존과 동일)
Future<void> _initializeBasicPackages() async {
  try {
    // ScreenUtil 초기화
    await ScreenUtil.ensureScreenSize();
    debugPrint('✅ ScreenUtil 초기화 성공');

    // 날짜 형식 초기화
    await initializeDateFormatting();
    debugPrint('✅ 날짜 형식 초기화 성공');

    // 환경변수 로드 (옵션)
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ 환경변수 로드 성공');
    } catch (e) {
      debugPrint('⚠️ .env 파일 로드 실패 (선택사항): $e');
    }
  } catch (e) {
    debugPrint('기본 패키지 초기화 오류: $e');
    // 중요하지 않은 초기화는 실패해도 계속 진행
  }
}

/// 카카오 SDK 초기화 (기존과 동일)
Future<void> _initializeKakaoSdk() async {
  try {
    final nativeKey = dotenv.get('KAKAO_NATIVE_APP_KEY', fallback: '');
    final jsKey = dotenv.get('KAKAO_JAVASCRIPT_APP_KEY', fallback: '');

    if (nativeKey.isNotEmpty && jsKey.isNotEmpty) {
      KakaoSdk.init(
        nativeAppKey: nativeKey,
        javaScriptAppKey: jsKey,
      );
      debugPrint('✅ 카카오 SDK 초기화 성공');
    } else {
      debugPrint('⚠️ 카카오 SDK 키가 설정되지 않았습니다');
    }
  } catch (e) {
    debugPrint('⚠️ 카카오 SDK 초기화 실패: $e');
    // 카카오 SDK 실패해도 앱은 계속 실행
  }
}

class AppDriver extends StatelessWidget {
  final VoidCallback onReset;

  const AppDriver({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeModeManager().themeModeNotifier,
        builder: (context, themeMode, child) {
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
                  ChangeNotifierProvider(create: (_) => BlockProvider()),
                  // 광고 프로바이더 - 싱글톤 인스턴스 사용
                  ChangeNotifierProvider.value(value: AdManager.instance),
                ],
                builder: (context, child) {
                  return child!;
                },
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: ThemeManager.lightTheme,
                  darkTheme: ThemeManager.darkTheme,
                  routerConfig: AppRoute.router,
                ),
              );
            },
          );
        }
    );
  }
}

/// 에러 발생 시 표시할 기본 앱
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: Colors.red[400],
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '앱 초기화 중 문제가 발생했습니다',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '잠시 후 다시 시도해주세요',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  Container(
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1.w,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '앱을 재시작해주세요',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  Key _appKey = UniqueKey();

  void resetApp() {
    if (mounted) {
      _appKey = UniqueKey();
      if (mounted) {
        // setState 최소화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      key: _appKey,
      onReset: resetApp,
    );
  }
}

/// 재시작을 위한 래퍼
class AppWrapper extends StatelessWidget {
  final VoidCallback onReset;

  const AppWrapper({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return AppDriver(onReset: onReset);
  }
}