
import 'package:my_sports_calendar/provider/auth/profile/Profile_Edit_Provider.dart';
import '../../manager/project/Import_Manager.dart';
import '../auth/register/Get_City.dart';
import '../auth/register/Get_Local.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return ChangeNotifierProvider(
      create: (_)=> ProfileEditProvider(userProvider.user!),
      builder: (context, child) {
        final provider = Provider.of<ProfileEditProvider>(context);
        return IosPopGesture(
          child: Scaffold(
            appBar: NadalAppbar(
              title: '프로필 편집',
            ),
            body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            //사용자 이미지 변경
                            Padding(
                                padding: EdgeInsets.only(top: 24),
                                child: Center(
                                  child: IntrinsicWidth(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.all(16),
                                            child: _profileFrame(provider.selectedImage == null ?
                                            provider.originUser['profileImage'] : provider.selectedImage?.path, 80)),
                                        Positioned(
                                            bottom: 0, right: 0,
                                            child: IconButton.filledTonal(
                                                style: ButtonStyle(
                                                    backgroundColor: WidgetStatePropertyAll(Colors.green[700])
                                                ),
                                                onPressed: () async{
                                                  await provider.pickImage;
                                                },
                                                constraints: BoxConstraints(
                                                  maxHeight: 24,
                                                  maxWidth: 24,
                                                  minHeight: 24,
                                                  minWidth: 24
                                                ),
                                                padding: EdgeInsets.zero,
                                                alignment: Alignment.center,
                                                iconSize: 13,
                                                icon: Icon(BootstrapIcons.camera_fill, color: const Color(0xfff1f1f1),)
                                            )
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                            //이메일
                            Center(
                              child: Text(provider.originUser['email'], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),),
                            ),
                            SizedBox(height: 24),
                            //닉네임
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 60),
                                child: NadalTextField(controller: provider.nickController, label: "닉네임", maxLength: 7, initText: provider.originUser['nickName'],)),
                            SizedBox(height: 16,),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 60),
                                child:  Row(
                                  children: [
                                    Flexible(child: GetLocal(local: provider.local, onTap: ()async{
                                      final res = await PickerManager.localPicker(provider.local);
                                      if(res != null){
                                        provider.setLocal(res);
                                      }
                                    })),
                                    SizedBox(width: 8,),
                                    Flexible(child: GetCity(local: provider.local, city: provider.city,
                                      onTap: ()async{
                                        if(provider.local.isEmpty){
                                          DialogManager.showBasicDialog(title: '알림', content: '지역 선택 후, 시/구/군을 선택해주세요', confirmText: '확인');
                                          return;
                                        }
              
                                        final res = await PickerManager.cityPicker(provider.city, provider.local);
              
                                        if(res != null){
                                          provider.setCity(res);
                                        }
                                      },
                                    ),)
                                  ],
                                ),
                            ),
                            SizedBox(height: 16,),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 60),
                              child: NadalTextField(controller: provider.careerController, maxLength: 2, label: '구력', keyboardType: TextInputType.number,
                                initText: AuthFormManager.careerDateToYearText(provider.originUser['career'])
                                    .replaceAll('초보', '0')
                                    .replaceAll('?', '0')
                                    .replaceAll('년', ''), suffixText: '년',),
                            ),
                            Padding(padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(),
                            ),
                            if(provider.originUser['verificationCode'] != null)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 60),
                                child: Column(
                                  children: [
                                    NadalVerificationInformation(),
                                    SizedBox(height: 24,),
                                    NadalReadOnlyContainer(label: '이름', value: provider.originUser['name']),
                                    SizedBox(height: 16,),
                                    NadalReadOnlyContainer(label: '성별', value: provider.originUser['gender'] == 'M' ? '남자' : provider.originUser['gender'] == 'F' ? '여자' : '알수없음'),
                                    SizedBox(height: 16,),
                                    NadalReadOnlyContainer(label: '출생연도', value: '${provider.originUser['birthYear'] ?? '알수없음'}'),
                                    SizedBox(height: 16,),
                                    NadalReadOnlyContainer(label: '휴대폰', value: '${provider.originUser['phone'] ?? '알수없음'}'),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 60),
                                child: Column(
                                  children: [
                                    NadalVerificationInformation(isVerification: false,),
                                    SizedBox(height: 24,),
                                    NadalTextField(controller: provider.nameController, label: '이름', maxLength: 10, initText: provider.originUser['name'],),
                                    SizedBox(height: 16,),
                                    Row(
                                      children: [
                                        Flexible(
                                            child: InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: ()=> provider.setGender('M'),
                                                child: NadalSelectableBox(selected: provider.gender == 'M', text: '남자'))
                                        ),
                                        SizedBox(width: 8,),
                                        Flexible(
                                            child: InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: ()=> provider.setGender('F'),
                                                child: NadalSelectableBox(selected: provider.gender == 'F', text: '여자'))
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16,),
                                    NadalTextField(controller: provider.birthYearController, label: '출생연도', maxLength: 4, initText: '${provider.originUser['birthYear']}', keyboardType: TextInputType.number),
                                  ],
                                ),
                              ),
                            SizedBox(height: 50,),
                          ],
                        ),
                      ),
                    ),
                    NadalButton(
                      isActive: true,
                      title: '저장',
                      onPressed: (){
                        provider.saveProfile();
                      },
                    )
                  ],
                )),
          ),
        );
      }
    );
  }

  Widget _profileFrame(String? url, double size){
    final isLocal = url != null && !url.startsWith('http');

    if(url != null && isLocal){
      return ClipPath(
        clipper: SoftEdgeClipper(),
        child: Container(
          height: size, width: size,
          decoration: BoxDecoration(
            color: Theme.of(AppRoute.navigatorKey.currentContext!).colorScheme.primary.withValues(alpha: 0.2),
            image: DecorationImage(image: FileImage(File(url)), fit: BoxFit.cover)
          ),
        ),
      );
    }

    return  NadalProfileFrame(imageUrl: url, size: size,);
  }
}
