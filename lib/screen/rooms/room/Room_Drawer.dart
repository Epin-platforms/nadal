import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/form/room/Grader_Form_Manger.dart';
import 'package:my_sports_calendar/model/share/Share_Parameter.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_Frame.dart';
import '../../../manager/project/Import_Manager.dart';
import '../../../widget/Share_Bottom_Sheet.dart';

class RoomDrawer extends StatefulWidget {
  const RoomDrawer({super.key, required this.roomId});
  final int roomId;

  @override
  State<RoomDrawer> createState() => _RoomDrawerState();
}

class _RoomDrawerState extends State<RoomDrawer> {
  final List<String> menu = ['club','member'];

  late RoomsProvider roomsProvider;
  late ChatProvider chatProvider;
  late RoomProvider provider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.roomId == -1){
        context.pop();
        DialogManager.errorHandler('올바른 접근이 아닙니다');
        return;
      }
      roomsProvider.updateRoom(widget.roomId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double size = 38.r;
    roomsProvider = Provider.of<RoomsProvider>(context);
    provider = Provider.of<RoomProvider>(context);
    chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final my = chatProvider.my[provider.room!['roomId']]!;
    final alarm = my['alarm'] == 1;
    final room  = provider.room!;

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          actions: [
            NadalIconButton(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => ShareBottomSheet(shareParameter: ShareParameter(
                      title: '${room['roomName']}',
                      link: null,
                      imageUrl: room['roomImage'] ?? 'https://cdn.imweb.me/thumbnail/20250520/d0cc0303965c0.png',
                      subTitle: '지금 바로 커뮤니티를 구경해볼까요?',
                      routing: '/room/${widget.roomId}'
                  ),),
                );
              },
              icon: CupertinoIcons.share
            ),
            SizedBox(width: 8.w,),
            NadalIconButton(
                onTap: () async{
                  final result = await provider.switchAlarm(alarm);
                  SnackBarManager.showCleanSnackBar(context, result);
                },
                icon:  alarm ?
                BootstrapIcons.bell : BootstrapIcons.bell_slash,
            ),
            SizedBox(width: 8.w,),
            if(my['grade'] < 2)
            NadalIconButton(
              onTap: () async{
                final router =  GoRouter.of(context);
                //바텀 시트
                final select = await showCupertinoModalPopup(context: context, builder: (context){
                  return NadalSheet(actions: [
                    if(my['grade'] == 0)
                    CupertinoActionSheetAction(onPressed: (){
                      Navigator.of(context).pop(menu[0]);
                    }, child: Text('클럽수정', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)),
                    CupertinoActionSheetAction(onPressed: (){
                      Navigator.of(context).pop(menu[1]);
                    }, child: Text('멤버수정', style: theme.textTheme.bodyLarge,)),
                  ]);
                });

                //라우팅
                if(select == menu[0]){
                  final res = await router.push('/room/${room['roomId']}/editRoom');

                  if(res != null){
                    roomsProvider.updateRoom(widget.roomId);
                  }
                }else if(select == menu[1]){
                  router.push('/room/${room['roomId']}/editMember');
                }
              },
              icon: BootstrapIcons.gear
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h,),
                    Center(child: NadalRoomFrame(size: 80.r, imageUrl: room['roomImage'])),
                    SizedBox(height: 12.h,),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(provider.room?['roomName'] ?? '알수없는 채팅방', style: theme.textTheme.titleLarge,)),
                    SizedBox(height: 4.h,),
                    Text('${room['local']} ${room['city']}', style: theme.textTheme.labelMedium,),
                    Text(DateFormat('yyyy.MM.dd').format(DateTime.parse(room['createAt']).toLocal()), style: theme.textTheme.labelSmall,),
                    SizedBox(height: 24.h,),
                    //방소개 탭
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: theme.highlightColor.withValues(alpha: 0.2)
                      ),
                      padding: EdgeInsets.all(12.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 30.w, height: 20.h,
                                child: FittedBox(
                                    fit: BoxFit.fitHeight,
                                    child: Icon(BootstrapIcons.chat_dots_fill, size: 24.r,)),
                              ),
                              Text('방 소개', style: theme.textTheme.titleSmall,),
                            ],
                          ),
                          SizedBox(height: 12.h,),
                          Container(
                              constraints: BoxConstraints(
                                maxHeight: 150.h,
                              ),
                              child: SingleChildScrollView(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(room['description'].isEmpty ?  '소개가 없습니다.' : room['description'], style: theme.textTheme.bodyMedium),
                                  if(room['tag'].isNotEmpty && room['description'].isNotEmpty)
                                  SizedBox(height: 4.h,),
                                  Text(room['tag'].isNotEmpty  ?  room['tag'] : '', style: theme.textTheme.bodyMedium?.copyWith(color: ThemeManager.infoColor)),
                                ],
                              )))
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: theme.highlightColor.withValues(alpha: 0.2)
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 12.w,),
                              SizedBox(width: 30.w, height: 20.h,
                                child: FittedBox(
                                    fit: BoxFit.fitHeight,
                                    child: Icon(BootstrapIcons.people_fill, size: 24.r,)),
                              ),
                              Text('인원 ${room['memberCount']}', style: theme.textTheme.titleSmall,),
                            ],
                          ),
                          SizedBox(height: 12.h,),
                          ListTile(
                            onTap: () async{
                              final notiProvider = context.read<NotificationProvider>();
                              final List<String>? res = await context.push('/friends?selectable=true');

                              if(res != null && res.isNotEmpty){
                                final users = provider.filterInviteAbleUsers(res);
                                if(users.length != res.length){
                                  SnackBarManager.showCleanSnackBar(context,
                                      '이미 참가 중인 사용자가 있어 제외하고 전송됩니다');
                                }
                                final failed = await notiProvider.sendNotification(
                                    receivers: users,
                                    title: '${provider.room!['roomName']} 커뮤니티에서 초대가 왔습니다',
                                    subTitle: '지금 바로 입장해볼까요?',
                                    routing: '/previewRoom/${provider.room!['roomId']}'
                                );
                                SnackBarManager.showCleanSnackBar(context, '${users.length - failed.length}/${users.length}명에게 초대장을 보냈습니다.');
                              }
                            },
                            minTileHeight: 42.h,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                            leading: ClipPath(
                              clipper: SoftEdgeClipper(),
                              child: Container(
                                height: size, width: size,
                                decoration: BoxDecoration(
                                  color: theme.highlightColor,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  BootstrapIcons.plus,
                                  size: size * 0.65,
                                ),
                              ),
                            ),
                            title: Text('초대하기', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),),
                          ),

                          Builder(
                            builder: (context) {
                              final user = context.read<UserProvider>().user!;
                              return ListTile(
                                onTap: (){
                                  context.push('/user/${my['uid']}');
                                },
                                minTileHeight: 42,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                leading: NadalProfileFrame(imageUrl: user['profileImage'], size: size,),
                                trailing: NadalMeTag(),
                                title: Text(TextFormManager.profileText(user['nickName'], user['name'], user['birthYear'], user['gender'], useNickname: room['useNickname'] == 1 ),
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                subtitle: Text(GraderFormManager.intToGrade(my['grade']), style: theme.textTheme.labelSmall?.copyWith(height: 1)),
                              );
                            }
                          ),

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
                                    context.push('/user/${member['uid']}');
                                  },
                                  minTileHeight: 42,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                    SizedBox(
                      height: 16,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: (){
                        if(my['grade'] == 0 && provider.roomMembers.entries.isNotEmpty){
                          DialogManager.showBasicDialog(title: '헉! 아직 나갈 수 없대요😅',
                              content: '아직 멤버가 있어요.\n클럽장을 바꾸면 나갈 수 있어요.\n지금 바로 할래요?',
                              cancelText: '위임할래요',
                              confirmText: '아니요 괜찮아요', onCancel: (){
                                context.push('/room/${room['roomId']}/editMember');
                          });
                        }else if(my['grade'] == 0 && provider.roomMembers.entries.isEmpty){
                          DialogManager.showBasicDialog(
                              title: '잠깐만요!',
                              content: '나가면 방이랑 채팅 기록이 모두 사라져요.\n정말 나가시겠어요?',
                              confirmText: '남아있을게요',
                              cancelText: '모든 데이터 삭제',
                              onCancel: () {
                                provider.deleteRoom(context);
                              });
                        }else{
                          DialogManager.showBasicDialog(
                              title: '클럽을 나가시겠어요?', 
                              content: '떠난 뒤에는 이 방의 채팅 기록을 다시 볼 수 없어요.\n정말 나가시겠어요?', 
                              confirmText: '남아있을게요', 
                              cancelText: '나갈레요', 
                              onCancel: ()=> provider.exitRoom(context));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.highlightColor.withValues(alpha: 0.2)
                        ),
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Text('채팅방 나가기', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w500),)
                      ),
                    )
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }
}
