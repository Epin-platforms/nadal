import 'package:my_sports_calendar/screen/auth/register/Birthyear_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Career_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Email_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Gender_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Get_City.dart';
import 'package:my_sports_calendar/screen/auth/register/Get_Local.dart';
import 'package:my_sports_calendar/screen/auth/register/Name_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Nickname_Field.dart';
import 'package:my_sports_calendar/screen/auth/register/Verification_Button.dart';
import '../../manager/project/Import_Manager.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late RegisterProvider registerProvider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_)=> registerProvider.resetForm());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    registerProvider = Provider.of<RegisterProvider>(context);
    return IosPopGesture(
      onPop: () async{
         await DialogManager.showBasicDialog(title: "로그인 페이지로 돌아갈까요?", content: "안전한 연결 해제를 위해\n로그인 화면으로 잠시 이동할게요.",
            confirmText: "돌아가기", onConfirm: ()=> userProvider.logout(true, false), cancelText: "취소");

         return false;
      },
      child: Stack(
        children: [
          Scaffold(
              appBar: NadalAppbar(
                onLeading: () async{
                  await DialogManager.showBasicDialog(title: "로그인 페이지로 돌아갈까요?", content: "안전한 연결 해제를 위해\n로그인 화면으로 잠시 이동할게요.",
                    confirmText: "돌아가기", onConfirm: ()=> userProvider.logout(true, false), cancelText: "취소",);
                },),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(registerProvider.verificationCode == null)
                                Padding(
                                    padding: EdgeInsets.only(bottom: 24.h),
                                    child: Text('간단한 정보만 입력하면\n곧 일정을 만들 수 있어요', style: Theme.of(context).textTheme.titleLarge,))
                              else
                                NadalVerificationInformation(),
                              if(FirebaseAuth.instance.currentUser?.email?.isEmpty ?? false) //만약 이메일이 없다면 입력받기
                                Padding(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    child: EmailField(registerProvider: registerProvider)),
                                Column(
                                  children: [
                                    if(registerProvider.visibleNameSpace)
                                      ...[
                                        if(registerProvider.verificationCode != null)
                                          SizedBox(height: 16.h,),
                                        NameField(registerProvider: registerProvider),
                                      ],

                                    if(registerProvider.genderSpace || registerProvider.birthYearSpace)
                                      ... [
                                        SizedBox(height: 16.h,),
                                        Row(
                                          children: [
                                            if(registerProvider.genderSpace)
                                              Expanded(
                                                  flex: 5,
                                                  child: GenderField(registerProvider: registerProvider)),
                                            if(registerProvider.genderSpace && registerProvider.birthYearSpace)
                                              SizedBox(width: 8.w,),
                                            if(registerProvider.birthYearSpace)
                                              Expanded(
                                                  flex: 4,
                                                  child: BirthYearField(registerProvider: registerProvider))
                                          ],
                                        ),
                                      ],

                                    if(registerProvider.verificationCode == null)
                                      ...[
                                        SizedBox(height: 16,),
                                        VerificationButton(registerProvider: registerProvider,)
                                      ]

                                  ],
                                ),
                              SizedBox(height: 24,),
                              Text('이제,\n아래 정보로 활동을 시작해볼까요?', style: Theme.of(context).textTheme.titleLarge,),
                              SizedBox(height: 24),
                              NicknameField(registerProvider: registerProvider),
                              SizedBox(height: 16,),
                              Row(
                                children: [
                                  Flexible(child: GetLocal(local: registerProvider.selectedLocal, onTap: () async{
                                    final res = await PickerManager.localPicker(registerProvider.selectedLocal);
                                    if(res != null){
                                      registerProvider.setLocal(res);
                                    }
                                  },)),
                                  SizedBox(width: 8,),
                                  Flexible(child: GetCity(
                                    local: registerProvider.selectedLocal,
                                    city: registerProvider.selectedCity,
                                    onTap: () async{
                                      if(registerProvider.selectedLocal.isEmpty){
                                        DialogManager.showBasicDialog(title: '알림', content: '지역 선택 후, 시/구/군을 선택해주세요', confirmText: '확인');
                                        return;
                                      }
                                      final res = await PickerManager.cityPicker(registerProvider.selectedCity, registerProvider.selectedLocal);

                                      if(res != null){
                                        registerProvider.setCity(res);
                                      }
                                    },
                                  )),
                                ],
                              ),
                              SizedBox(height: 24,),
                              CareerField(registerProvider: registerProvider,)
                            ],
                          ),
                        ),
                      ),
                    ),
                    NadalButton(isActive: true, onPressed: ()=> registerProvider.signUp(),)
                  ],
                ),
              )
          ),
          if(registerProvider.loading)
            LoadingBlock()
        ],
      ),
    );
  }
}
