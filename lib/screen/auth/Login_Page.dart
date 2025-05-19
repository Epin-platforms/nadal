import 'package:my_sports_calendar/screen/auth/login/Apple_Button.dart';
import 'package:my_sports_calendar/screen/auth/login/Google_Button.dart';
import 'package:my_sports_calendar/screen/auth/login/Kakao_Button.dart';
import '../../manager/auth/social/Kakao_Manager.dart';
import '../../manager/project/Import_Manager.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              // 앱 로고
              Image.asset("assets/image/app/login_logo.png"),

              Text(
                '오늘부터 나달과 함께하는 스포츠 라이프!',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 10),
              Text(
                '소셜 계정으로 간편하게 시작하세요',
                style: Theme.of(context).textTheme.labelMedium,
              ),

              const SizedBox(height: 20),
      
              // 소셜 로그인 버튼들
              Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                          onTap: (){
                            KakaoManager().kakaoLogin();
                          },
                          child: KakaoButton()),
                      GoogleButton(),
                      if(Platform.isIOS)
                        AppleButton()
                    ],
                  )
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
                    onTap: (){},
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
                    onTap: (){},
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
