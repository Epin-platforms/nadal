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
    WidgetsBinding.instance.addPostFrameCallback((_){
      _stepToSettingApp();
    });
    super.initState();
  }

  void _stepToSettingApp() async{
    await _startProviderInit();
  }


  Future<void> _startProviderInit() async{
    final res = await appProvider.initAppProvider();
    if(res == AppProviderState.none){
      DialogManager.showBasicDialog(title: '알수없는 이유로 로그인에 실패했습니다', content: '다시 시도해주세요', confirmText: '확인');
    }else if(res == AppProviderState.inspection){
      DialogManager.inspectionHandler(); //업데이트 다이알로그 띄우기
    }else if(res == AppProviderState.update){
      DialogManager.updateHandler(); //업데이트 다이알로그 띄우기
    }else{
      userProvider.userProviderInit();
    }
  }

  @override
  Widget build(BuildContext context) {
    appProvider = Provider.of<AppProvider>(context);
    userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Container(
        decoration:  BoxDecoration(
          gradient: ThemeManager.primaryGradient
        ),
        child: Center(
          child: BounceWidget(child: Image.asset('assets/image/app/splash_icon.png', height: 100, width: 100, fit: BoxFit.cover,))
        ),
      ),
    );
  }
}
