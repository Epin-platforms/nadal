import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/widget/Nadal_Empty_List.dart';
import 'package:my_sports_calendar/widget/Nadal_Icon_Button.dart';
import 'package:my_sports_calendar/widget/Nadal_PlaceHolder_Container.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_NotRead_Tag.dart';

import '../../../manager/project/Import_Manager.dart';
import '../../../widget/Nadal_Room_Frame.dart';

class MyRooms extends StatelessWidget {
  const MyRooms({super.key});

  @override
  Widget build(BuildContext context) {
    final roomsProvider = Provider.of<RoomsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.only(left: 16, bottom: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MY 클럽 & 커뮤니티', style: Theme.of(context).textTheme.titleLarge,),
                Row(
                  children: [
                    NadalIconButton(
                        onTap: (){
                          context.push('/searchRoom');
                        },
                        icon: CupertinoIcons.search,
                    ),
                    SizedBox(width: 8,),
                    NadalIconButton(
                        onTap: (){
                          context.push('/createRoom');
                          },
                        image: 'assets/image/icon/chat_add.png',
                    )
                  ],
                )
              ],
            ),
          ),
          if(roomsProvider.rooms == null)
            ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index){
                  return ListTile(
                    leading: NadalProfileFrame(isPlaceHolder: true),
                    title: NadalPlaceholderContainer(height: 18,),
                    subtitle: NadalPlaceholderContainer(height: 15, width: 100,),
                  );
                },
                separatorBuilder: (context,index)=> Divider(),
                itemCount: 3
            )
          else if(roomsProvider.rooms!.isNotEmpty)
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: roomsProvider.getRoomsList(context).length,
                itemBuilder: (context, index){
                  final roomEntry = roomsProvider.getRoomsList(context)[index];
                  final roomData = roomEntry.value;
                  final chatForm = chatProvider.chat[roomData['roomId']]?.firstOrNull;
                  final chatText = chatForm == null ? '' : chatForm.type == ChatType.text ? chatForm.contents : chatForm.type == ChatType.image ? '사진' : chatForm.type == ChatType.schedule ? '일정' : '삭제된 메시지 입니다';
                  final unread = chatProvider.my[roomData['roomId']]?['unreadCount'];
                  return ListTile(
                    onTap: ()=> context.push('/room/${roomData['roomId']}'),
                    leading: NadalRoomFrame(imageUrl: roomData['roomImage'],),
                    title: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              text: roomData['roomName'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                              children: [
                                TextSpan(
                                  text: ' ${roomData['memberCount'] ?? 0}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 24
                        ),
                        child: Text(chatText ?? '', style: Theme.of(context).textTheme.labelMedium,)),
                    trailing: unread != null && unread != 0 ? NadalRoomNotReadTag(number: unread) : null,
                  );
                })
          else
            SizedBox(
              height: 300,
              child: NadalEmptyList(
                title: '아직 참여한 클럽이 없어요',
                subtitle: '근처 클럽을 찾아보거나, 새로운 클럽을 만들어보세요',
                onAction: () => GoRouter.of(context).push('/searchRoom'),
                icon: Icon(CupertinoIcons.search),
                actionText: '클럽 둘러보기',),
            )
        ],
      )
    );
  }
}
