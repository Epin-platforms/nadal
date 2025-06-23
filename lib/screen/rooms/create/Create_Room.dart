import 'package:my_sports_calendar/provider/room/Create_Room_Provider.dart';
import 'package:my_sports_calendar/screen/auth/register/Get_City.dart';
import 'package:my_sports_calendar/screen/auth/register/Get_Local.dart';

import '../../../manager/project/Import_Manager.dart';

class CreateRoom extends StatelessWidget {
  const CreateRoom({super.key, required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user!;
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_)=> CreateRoomProvider(user['local'], user['city'], isOpen),
      builder: (context, child){
        final provider = Provider.of<CreateRoomProvider>(context);
        return IosPopGesture(
          child: GestureDetector(
            onTap: ()=> FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: NadalAppbar(title: '${isOpen ? '번개방' : '클럽'} 생성'),
              body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  SizedBox(height: 40.h,),
                                  Text('나만의 ${isOpen ? '번개방' : '클럽'}을 시작해볼까요?', style: theme.textTheme.titleLarge,),
                                  if(isOpen)...[
                                    SizedBox(height: 8.h,),
                                    Text('번개방은 누구나 자유롭게 생성하고 삭제 할 수 있어요!', style: theme.textTheme.bodySmall,),
                                    SizedBox(height: 4.h,),
                                    Text('한달 간 활동 내역이 없으면 자동 삭제되니 주의해주세요', style: theme.textTheme.bodySmall,)
                                  ],
                                  SizedBox(height: 24.h,),
                                  NadalTextField(controller: provider.roomNameController, label: isOpen ? '번개방 제목' : '클럽 명', maxLength: 30,),
                                  SizedBox(height: 36.h),
                                  Row(
                                    children: [ 
                                      SizedBox(
                                          width: 62.w,
                                          child: Text('활동지역', style: theme.textTheme.titleSmall,)),
                                      Flexible(child: GetLocal(local: provider.local, onTap: () async{
                                        final res = await PickerManager.localPicker(provider.local);
                                        if(res != null){
                                          provider.setLocal(res);
                                        }
                                      })),
                                      SizedBox(width: 8,),
                                      Flexible(child: GetCity(city: provider.city, onTap: () async{
                                        if(provider.local.isEmpty){
                                          DialogManager.showBasicDialog(title: '알림', content: '지역 선택 후, 시/구/군을 선택해주세요', confirmText: '확인');
                                          return;
                                        }
                                        final res = await PickerManager.cityPicker(provider.city, provider.local);

                                        if(res != null){
                                          provider.setCity(res);
                                        }
                                      }, local: provider.local))
                                    ],
                                  ),
                                  SizedBox(height: 16.h,),
                                  Row(
                                    children: [
                                      SizedBox(
                                          width: 62.w,
                                          child: Text('활동방식', style: theme.textTheme.titleSmall,)),
                                      Flexible(child: InkWell(
                                          onTap: (){
                                            provider.setUseNickname(true);
                                          },
                                          child: NadalSelectableBox(selected: provider.useNickname, text: '닉네임으로 활동', ))),
                                      SizedBox(width: 8.w,),
                                      Flexible(child: InkWell(
                                        onTap: (){
                                          if(user['verificationCode'] == null){
                                            DialogManager.showBasicDialog(title: '앗! 이런', content: '본명은 인증된 사용자만 가능해요', confirmText: '확인', icon: Icon(BootstrapIcons.emoji_tear));
                                          }else{
                                            provider.setUseNickname(false);
                                          }
                                        },
                                        child: NadalSelectableBox(
                                            selected: !provider.useNickname,
                                            text: '본명으로 활동'),
                                      )),
                                    ],
                                  ),
                                  SizedBox(height: 16.h,),
                                  if(!provider.isOpen)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: 62.w,
                                          height: 48.h,
                                          alignment: Alignment.centerLeft,
                                          child: Text('참가코드', style: theme.textTheme.titleSmall,)),
                                      Expanded(child: NadalTextField(controller: provider.enterCodeController, label: '비밀번호', maxLength: 10, keyboardType: TextInputType.number, helper: '4자리 이상 10자리 이하의 숫자를 입력해 주세요!',)),
                                    ],
                                  ),
                                SizedBox(height: 36.h,),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    runSpacing: 4,
                                    children: [
                                      SizedBox(
                                          width: 62.w,
                                          child: Text('태그입력', style: theme.textTheme.titleSmall,)),
                                      ...List.generate(provider.tags.length, (index)=> Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(3)
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(provider.tags[index], style: theme.textTheme.labelMedium,),
                                              SizedBox(width: 4,),
                                              InkWell(
                                                  customBorder: CircleBorder(),
                                                  onTap: (){
                                                    provider.removeTag(index);
                                                  },
                                                  child: Icon(BootstrapIcons.x_circle_fill, color: theme.hintColor, size: 15,))
                                            ],
                                          ),
                                        ),
                                      )),
                                      IntrinsicWidth(
                                        child: TextField(
                                          controller: provider.tagController,
                                          onChanged: (value)=> provider.setTag(value),
                                          style: theme.textTheme.labelMedium,
                                          maxLength: 18,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            constraints: BoxConstraints(
                                              maxHeight: 32.5,
                                            ),
                                            counter: null,
                                            counterText: '',
                                            filled: true,
                                            fillColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(3),
                                              borderSide: BorderSide.none
                                            )
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  if(provider.tags.isEmpty)
                                    Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text('태그는 쉼표(,)로 구분해서 여러개를 만들수있어요', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary),)),
                                  SizedBox(height: 16.h,),
                                  NadalTextField(controller: provider.descriptionController, label: '${isOpen ? '번개방' : '클럽'} 설명', isMaxLines: true, keyboardType: TextInputType.multiline,),
                                  SizedBox(height: 50,)
                              ],
                            ),
                          ),
                        ),
                      ),
                      NadalButton(
                        onPressed: () async{
                          if(TextFormManager.removeSpace(provider.tagController.text.replaceAll('#', '')).isNotEmpty){
                            await DialogManager.showBasicDialog(title: '작성중인 태그가존재해요', content: '작성중인 태그를 등록할까요?',
                                cancelText: '아니오',
                                confirmText: '네',
                                onConfirm: (){
                                  provider.setTag('${provider.tagController.text},');
                                }
                            );
                          }
                          provider.createRoom();
                        },
                        isActive: true,
                        title: '${isOpen ? '번개방' : '클럽'} 채팅 시작하기',
                      ),
                      if(Platform.isIOS)
                        SizedBox(
                          height: 15,
                        )
                    ],
                  )
              )
            ),
          ),
        );
      },
    );
  }
}
