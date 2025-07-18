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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      registerProvider = context.read<RegisterProvider>();
      registerProvider.resetForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        registerProvider = provider; // 상태 업데이트 시마다 갱신

        return IosPopGesture(
          onPop: () async{
            await DialogManager.showBasicDialog(
                title: "로그인 페이지로 돌아갈까요?",
                content: "안전한 연결 해제를 위해\n로그인 화면으로 잠시 이동할게요.",
                confirmText: "돌아가기",
                onConfirm: () => userProvider.logout(true, false),
                cancelText: "취소"
            );
            return false;
          },
          child: Stack(
            children: [
              Scaffold(
                  appBar: NadalAppbar(
                    onLeading: () async{
                      await DialogManager.showBasicDialog(
                          title: "로그인 페이지로 돌아갈까요?",
                          content: "안전한 연결 해제를 위해\n로그인 화면으로 잠시 이동할게요.",
                          confirmText: "돌아가기",
                          onConfirm: () => userProvider.logout(true, false),
                          cancelText: "취소"
                      );
                    },
                  ),
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
                                  if(provider.verificationCode == null)
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 24.h),
                                        child: Text(
                                          '간단한 정보만 입력하면\n곧 일정을 만들 수 있어요',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        )
                                    )
                                  else
                                    NadalVerificationInformation(),

                                  if(provider.emailSpace)
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: EmailField(registerProvider: provider)
                                    ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if(provider.visibleNameSpace) ...[
                                        if(provider.verificationCode != null)
                                          SizedBox(height: 16.h),
                                        NameField(registerProvider: provider),
                                      ],

                                      if(provider.genderSpace || provider.birthYearSpace) ...[
                                        SizedBox(height: 16.h),
                                        Row(
                                          children: [
                                            if(provider.genderSpace)
                                              Expanded(
                                                  flex: 5,
                                                  child: GenderField(registerProvider: provider)
                                              ),
                                            if(provider.genderSpace && provider.birthYearSpace)
                                              SizedBox(width: 8.w),
                                            if(provider.birthYearSpace)
                                              Expanded(
                                                  flex: 4,
                                                  child: BirthYearField(registerProvider: provider)
                                              )
                                          ],
                                        ),
                                        Text(
                                          '- 해당 데이터는 선택 사항입니다, 카카오 인증 시에만 사용됩니다',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],

                                      if(provider.verificationCode == null) ...[
                                        SizedBox(height: 16.h),
                                        VerificationButton(registerProvider: provider)
                                      ]
                                    ],
                                  ),

                                  SizedBox(height: 24.h),
                                  Text(
                                    '이제,\n아래 정보로 활동을 시작해볼까요?',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),

                                  SizedBox(height: 24.h),
                                  NicknameField(registerProvider: provider),

                                  SizedBox(height: 16.h),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: GetLocal(
                                            local: provider.selectedLocal,
                                            onTap: () async{
                                              final res = await PickerManager.localPicker(provider.selectedLocal);
                                              if(res != null){
                                                provider.setLocal(res);
                                              }
                                            },
                                          )
                                      ),
                                      SizedBox(width: 8.w),
                                      Flexible(
                                          child: GetCity(
                                            local: provider.selectedLocal,
                                            city: provider.selectedCity,
                                            onTap: () async{
                                              if(provider.selectedLocal.isEmpty){
                                                DialogManager.showBasicDialog(
                                                    title: '알림',
                                                    content: '지역 선택 후, 시/구/군을 선택해주세요',
                                                    confirmText: '확인'
                                                );
                                                return;
                                              }
                                              final res = await PickerManager.cityPicker(
                                                  provider.selectedCity,
                                                  provider.selectedLocal
                                              );
                                              if(res != null){
                                                provider.setCity(res);
                                              }
                                            },
                                          )
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '- (필수)같은 지역 내 모임 추천을위해 사용됩니다',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: 24.h),
                                  CareerField(registerProvider: provider)
                                ],
                              ),
                            ),
                          ),
                        ),
                        NadalButton(
                          isActive: true,
                          onPressed: () => provider.signUp(),
                        )
                      ],
                    ),
                  )
              ),

              if(provider.loading)
                LoadingBlock()
            ],
          ),
        );
      },
    );
  }
}