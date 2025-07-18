import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/project/ThemeMode_Manager.dart';
import 'package:my_sports_calendar/screen/auth/login/Apple_Button.dart';
import 'package:my_sports_calendar/screen/auth/login/Google_Button.dart';
import 'package:my_sports_calendar/screen/auth/login/Kakao_Button.dart';
import '../../main.dart';
import '../../manager/auth/social/Kakao_Manager.dart';
import '../../manager/project/Import_Manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.reset});
  final bool reset;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool reviewMode;
  // 🔧 로고 탭 카운트 관련 변수들
  int _logoTapCount = 0;
  DateTime? _firstTapTime;
  static const int _requiredTaps = 5;
  static const int _tapTimeLimit = 3; // 3초 내에 5번 탭해야 함

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      isReviewMode();
    });
    if(widget.reset){
      final root = context.findAncestorStateOfType<RootAppState>();
      root?.resetApp();
    }
    super.initState();
  }

  void isReviewMode() async{
    final doc = await FirebaseFirestore.instance.collection('app').doc('review').get();
    final mode = doc.data();
    print('현재 모드: $mode');
    if(mode != null){
      reviewMode = mode['mode'];
    }
    setState(() {});
  }

  String logoPathByBrightness(){
    final themeMode = ThemeModeManager().currentTheme;
    if(themeMode == ThemeMode.system){
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark ? "assets/image/app/login_logo_dark.png" : "assets/image/app/login_logo.png";
    }else if(themeMode == ThemeMode.dark){
      return "assets/image/app/login_logo_dark.png";
    }else{
      return "assets/image/app/login_logo.png";
    }
  }

  // 🔧 로고 탭 처리 함수
  void _onLogoTapped() {
    if(!reviewMode) return;
    final now = DateTime.now();

    // 첫 번째 탭이거나 시간 제한 초과 시 리셋
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!).inSeconds > _tapTimeLimit) {
      _logoTapCount = 1;
      _firstTapTime = now;
      print('🔧 로고 탭 시작: ${_logoTapCount}/$_requiredTaps');
      return;
    }

    // 연속 탭 카운트 증가
    _logoTapCount++;
    print('🔧 로고 탭 카운트: ${_logoTapCount}/$_requiredTaps');

    // 5번 탭 완료 시 숨겨진 기능 실행
    if (_logoTapCount >= _requiredTaps) {
      _activateReviewMode();
      // 카운트 리셋
      _logoTapCount = 0;
      _firstTapTime = null;
    }
  }

  // 🔧 앱 심사용 숨겨진 기능 실행
  void _activateReviewMode() {
    print('🍎 Apple Review Mode 활성화!');

    // 햅틱 피드백
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.apple, color: Colors.blue, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              'Apple Review Mode',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            Text(
              '• 이 정보는 애플 앱 리뷰어 전용입니다\n'
                  '• 일반 사용자에게는 보이지 않습니다\n'
                  '• 출시 후 서버내에서 해당 기능을 차단합니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedWithReviewAccount();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Review Account으로 로그인'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
        ],
      ),
    );
  }

  // 🔧 리뷰 계정으로 자동 로그인 진행
  void _proceedWithReviewAccount() async{
    // 여기서 실제 리뷰 계정 로그인 로직 구현
    // 예: 특별한 플래그 설정 후 자동 로그인
    print('🍎 Apple Review Account 자동 로그인 시작...');

    // TODO: 실제 리뷰 계정 로그인 로직 호출
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'appleReview@nasdal.com',
        password: '1q2w3e4r@@'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100.h),

              // 🔧 앱 로고 - GestureDetector로 감싸서 탭 감지
              GestureDetector(
                onTap: _onLogoTapped,
                child: Container(
                  // 탭 영역을 좀 더 넓게 만들기 위한 padding
                  padding: EdgeInsets.all(16.w),
                  child: Image.asset(logoPathByBrightness()),
                ),
              ),

              Text(
                '오늘부터 나스달과 함께하는 스포츠 라이프!',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              SizedBox(height: 10.h),
              Text(
                '소셜 계정으로 간편하게 시작하세요',
                style: Theme.of(context).textTheme.labelMedium,
              ),

              Spacer(),

              // 소셜 로그인 버튼들
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                      onTap: (){
                        KakaoManager().kakaoLogin();
                      },
                      child: KakaoButton()),
                  SizedBox(height: 12.h,),
                  GoogleButton(),
                  if(Platform.isIOS) ...[
                    SizedBox(height: 12.h,),
                    AppleButton()
                  ]
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '로그인 시 ',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                  InkWell(
                    onTap: (){
                      final url = dotenv.get('PRIVACY_POLICY');
                      context.push('/web?url=$url');
                    },
                    child: Text(
                      '개인정보 처리방침',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    ' 및 ',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                  InkWell(
                    onTap: (){
                      final url = dotenv.get('TERM_OF_USE');
                      context.push('/web?url=$url');
                    },
                    child: Text(
                      '이용약관',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    '에 동의합니다.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}