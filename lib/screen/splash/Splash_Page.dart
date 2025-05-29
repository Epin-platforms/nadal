import 'package:my_sports_calendar/screen/splash/widget/Bounce_Widget.dart';
import '../../manager/project/Import_Manager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late AppProvider appProvider;
  late UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stepToSettingApp();
    });
  }

  void _stepToSettingApp() async {
    await _startProviderInit();
  }

  Future<void> _startProviderInit() async {
    try {
      // AppProvider 초기화
      final res = await appProvider.initAppProvider();

      if (res == AppProviderState.none) {
        DialogManager.showBasicDialog(
            title: '알수없는 이유로 로그인에 실패했습니다',
            content: '다시 시도해주세요',
            confirmText: '확인'
        );
      } else if (res == AppProviderState.inspection) {
        DialogManager.inspectionHandler(); // 검수 다이얼로그
      } else if (res == AppProviderState.update) {
        DialogManager.updateHandler(); // 업데이트 다이얼로그
      } else {
        // 🔥 Firebase 초기화 완료 후에만 UserProvider 초기화
        userProvider.userProviderInit();
      }
    } catch (e) {
      print('❌ Provider 초기화 실패: $e');
      DialogManager.showBasicDialog(
          title: '초기화 오류',
          content: '앱 초기화 중 오류가 발생했습니다. 다시 시도해주세요.',
          confirmText: '확인'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 안전하게 Provider 접근
    try {
      appProvider = Provider.of<AppProvider>(context, listen: false);
      userProvider = Provider.of<UserProvider>(context, listen: false);
    } catch (e) {
      print('❌ Provider 접근 실패: $e');
      // Provider에 접근할 수 없는 경우 기본 UI 표시
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: ThemeManager.primaryGradient
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  '앱을 초기화하는 중...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: ThemeManager.primaryGradient
        ),
        child: Center(
            child: BounceWidget(
                child: Image.asset(
                  'assets/image/app/splash_icon.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                )
            )
        ),
      ),
    );
  }
}