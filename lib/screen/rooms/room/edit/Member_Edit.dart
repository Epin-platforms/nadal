import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import '../../../../manager/form/room/Grader_Form_Manger.dart';
import '../../../../manager/project/Import_Manager.dart';

class MemberEdit extends StatelessWidget {
  const MemberEdit({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomProvider>(context);
    final room = provider.room!;
    final my = context.read<ChatProvider>().my[room['roomId']];
    final double size = 45;
    final theme = Theme.of(context);

    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '멤버 수정',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24,),
                  Builder(
                      builder: (context) {
                        final user = context.read<UserProvider>().user!;
                        return ListTile(
                          onTap: (){

                          },
                          minTileHeight: 45,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: NadalProfileFrame(imageUrl: user['profileImage'], size: size,),
                          trailing: NadalMeTag(size: 18,),
                          title: Text(TextFormManager.profileText(user['nickName'] , user['name'], user['birthYear'], user['gender'], useNickname: room['useNickname'] == 1),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Text(GraderFormManager.intToGrade(my!['grade']), style: theme.textTheme.labelSmall?.copyWith(height: 1)),
                        );
                      }
                  ),

                  Divider(height: 0.5,),
                  ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: provider.roomMembers.length,
                      itemBuilder: (context, index){
                        final list = provider.roomMembers.entries.toList();
                        final member = list[index].value;
                        return ListTile(
                          onTap: (){
                            showCupertinoModalPopup(context: context, builder: (ctx){
                              final nav = Navigator.of(ctx);
                              return NadalSheet(
                                  title: '멤버에게 권한을 부여합니다',
                                  message: '클럽 정보 수정은 클럽장만 가능합니다',
                                  actions: [
                                    ...List.generate(4, (index){
                                      final label =  GraderFormManager.intToGrade(index);
                                      return CupertinoActionSheetAction(onPressed: (){
                                        nav.pop();

                                        if(member['grade'] <= context.read<ChatProvider>().my[room['roomId']]!['grade']){ //나의 권한이랑 같거나 작으면 강퇴불가
                                          DialogManager.showBasicDialog(  title: "이 멤버는 수정할 수 없어요",
                                            content: "본인과 같은 권한이거나 더 높은 권한을 가진 멤버예요.",
                                            confirmText: "알겠어요",);
                                          return;
                                        }

                                        DialogManager.showBasicDialog(
                                            title: '이 멤버를 등급을 변경할까요?',
                                            content: "등급이 변경된 멤버에게 알림이 갑니다",
                                            confirmText: "변경할게요", cancelText: '잠깐만요!',
                                            onConfirm: () => provider.onChangedMemberGrade(member['uid'], index)
                                        );

                                      }, child: Text(label, style: theme.textTheme.bodyLarge,));
                                    }),
                                    CupertinoActionSheetAction(onPressed: (){
                                    nav.pop();
                                    if(member['grade'] <= context.read<ChatProvider>().my[room['roomId']]!['grade']){ //나의 권한이랑 같거나 작으면 강퇴불가
                                      DialogManager.showBasicDialog(  title: "이 멤버는 추방할 수 없어요",
                                        content: "본인과 같은 권한이거나 더 높은 권한을 가진 멤버예요.",
                                        confirmText: "알겠어요",);
                                      return;
                                    }

                                    DialogManager.showBasicDialog(title: '이 멤버를 채팅방에서 내보낼까요?', content: "추방된 멤버는 2개월간 이 채팅방에\n다시 참여할 수 없습니다.", confirmText: "그만둘래요", cancelText: '네, 추방할게요',
                                      onCancel: () async{
                                        final data = {
                                          'uid' : member['uid'],
                                          'roomId' : member['roomId']
                                        };
                                        await serverManager.post('roomMember/kick', data: data);
                                      }
                                    );
                                    }, child: Text('추방', style: theme.textTheme.bodyLarge,))
                                  ]
                              );
                            });
                          },
                          minTileHeight: 45,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: NadalProfileFrame(imageUrl: member['profileImage'], size: size,),
                          title: Text(TextFormManager.profileText(member['displayName'] , member['displayName'], member['birthYear'], member['gender'], useNickname: room['useNickname'] == 1 ),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                          ),
                          subtitle: Text(GraderFormManager.intToGrade(member['grade']), style: theme.textTheme.labelSmall?.copyWith(height: 1)),
                        );
                      }),
                ],
              ),
            ),
          )
        )
    );
  }
}
