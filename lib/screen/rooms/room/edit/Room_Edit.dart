
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/room/Edit_Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';
import '../../../../provider/room/Room_Provider.dart';
import '../../../auth/register/Get_City.dart';
import '../../../auth/register/Get_Local.dart';

class RoomEdit extends StatelessWidget {
  const RoomEdit({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = Provider.of<RoomProvider>(context);
    return ChangeNotifierProvider(
      create: (_)=> EditRoomProvider(roomProvider.room!),
      builder: (context, child) {
        final provider = Provider.of<EditRoomProvider>(context);
        return IosPopGesture(
            child: Scaffold(
              appBar: NadalAppbar(
                title: '클럽 수정',
              ),
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
                                  //방 이미지 수정
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
                                                provider.originRoom['roomImage'] : provider.selectedImage?.path, 80)),
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
                                SizedBox(
                                  height: 24,
                                ),
                                NadalTextField(controller: provider.roomNameController, initText: provider.originRoom['roomName'], maxLength: 30, label: '클럽이름',),
                                SizedBox(height: 16,),
                                NadalTextField(controller: provider.descriptionController, initText: provider.originRoom['description'], maxLines: null, label: '클럽 소개',),
                                SizedBox(height: 24,),

                                //태그
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 4,
                                  children: [
                                    SizedBox(
                                        width: 62,
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

                                SizedBox(height: 24,),

                                //패스워드 사용
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 62,
                                        child: Text('참가코드', style: theme.textTheme.titleSmall,)),
                                    Flexible(child: InkWell(
                                        onTap: (){
                                          provider.setUseEnterCode(true);
                                        },
                                        child: NadalSelectableBox(selected: provider.useEnterCode, text: '참가코드 사용'))),
                                    SizedBox(width: 8,),
                                    Flexible(child: InkWell(
                                      onTap: (){
                                        provider.setUseEnterCode(false);
                                      },
                                      child: NadalSelectableBox(
                                          selected: !provider.useEnterCode,
                                          text: '참가코드 사용안함'),
                                    )),
                                  ],
                                ),
                                if(provider.useEnterCode)
                                  Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: NadalTextField(controller: provider.enterCodeController, label: '비밀번호', maxLength: 10, keyboardType: TextInputType.number, helper: '4자리 이상 10자리 이하의 숫자를 입력해 주세요!', initText: provider.originRoom['enterCode'],)),

                                SizedBox(height: 16,),
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 62,
                                        child: Text('활동방식', style: theme.textTheme.titleSmall,)),
                                    Flexible(child: InkWell(
                                        onTap: (){
                                          provider.setUseNickname(true);
                                        },
                                        child: NadalSelectableBox(selected: provider.useNickname, text: '닉네임으로 활동', ))),
                                    SizedBox(width: 8,),
                                    Flexible(child: InkWell(
                                      onTap: (){
                                        if(context.read<UserProvider>().user!['verificationCode'] == null){
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
                                SizedBox(height: 16,),
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 62,
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
                                SizedBox(height: 50,),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final date = DateTime.parse(provider.originRoom['updateAt']).add(const Duration(days: 7));
                          final bool active = provider.originRoom['updateAt'] != provider.originRoom['createAt'] && date.isBefore(DateTime.now());

                          return NadalButton( //업데이트한지 7일이 안되면 flase
                              onPressed: (){
                                if(active){
                                  DialogManager.showBasicDialog(title: '정말 수정할까요?', content: '클럽 정보는 일주일에 한번만 수정 가능해요', confirmText: '수정하기', cancelText: '취소', onConfirm: (){
                                    final isHaveAllCode = roomProvider.roomMembers.values.where((e)=> e['verificationCode'] == null).isEmpty;
                                    provider.updateRoom(isHaveAllCode);
                                  });
                                }else{
                                  DialogManager.showBasicDialog(title: '앗! 이런...', content: '클럽 수정은 일주일에 한번만 가능합니다', confirmText: '확인');
                                }
                              },
                              isActive: active ? true : false,
                              title: active ? '수정하기' : DateFormat('MM월 dd일 이후 수정 가능').format(date),
                          );
                        }
                      ),
                    ],
                  )
              ),
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

    return  NadalRoomFrame(imageUrl: url, size: size,);
  }
}
