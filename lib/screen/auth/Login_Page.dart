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

  @override
  void initState() {
    if(widget.reset){
      final root = context.findAncestorStateOfType<RootAppState>();
      root?.resetApp();
    }
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100.h),
              // 앱 로고
              Builder(
                builder: (context) {
                  final brightness = MediaQuery.of(context).platformBrightness;
                  final logoPath = brightness == Brightness.dark
                      ? "assets/image/app/login_logo_dark.png"
                      : "assets/image/app/login_logo.png";
                  return Image.asset(logoPath);
                }
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
