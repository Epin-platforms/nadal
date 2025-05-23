import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Image_Chat_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Removed_Chat_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Reply_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Schedule_Chat_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Text_Chat_Bubble.dart';
import '../../../../../manager/project/Import_Manager.dart';

class ChatFrame extends StatefulWidget {
  const ChatFrame({
    super.key,
    required this.chat,
    required this.timeVisible,
    required this.tail,
    required this.read,
    required this.index, required this.roomProvider,
  });

  final Chat chat;
  final bool timeVisible;
  final bool tail;
  final int read;
  final int index;
  final RoomProvider roomProvider;
  @override
  State<ChatFrame> createState() => _ChatFrameState();
}

class _ChatFrameState extends State<ChatFrame> {
 // 애니메이션 지연 계산용 인덱스

  void _chatAction(theme, isSender){
    if(widget.chat.type == ChatType.removed){
      return;
    }

    showCupertinoModalPopup(
        context: context,
        builder: (context){
          final nav = Navigator.of(context);
          return  NadalSheet(actions: [
            //공통
            CupertinoActionSheetAction(
                onPressed: (){
                  nav.pop();
                },
                child: Text('복사', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
            ),

            CupertinoActionSheetAction(
                onPressed: (){
                  nav.pop();
                    widget.roomProvider.setReply(widget.chat.chatId);
                },
                child: Text('답장', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
            ),

            if(!isSender)
            CupertinoActionSheetAction(
                onPressed: (){
                  nav.pop();
                  context.push('/report?targetId=${widget.chat.chatId}&type=chat');
                },
                child: Text('신고', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
            ),

            if(widget.chat.type != ChatType.removed && isSender)
              CupertinoActionSheetAction(
                  onPressed: () async{
                    nav.pop();
                    await serverManager.put('chat/remove/${widget.chat.chatId}?roomId=${widget.chat.roomId}');
                  },
                  child: Text('삭제', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
              ),
            ],
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toLocal();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSender = (widget.chat.uid == context.read<UserProvider>().user?['uid']);

    // 발신자 메시지 (오른쪽 정렬)
    if (isSender) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 읽음 표시
          if (widget.read != 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${widget.read > 99 ? "99+" : widget.read}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // 시간 표시
          if (widget.timeVisible)
            Container(
              margin: const EdgeInsets.only(right: 6, bottom: 4),
              child: Text(
                TextFormManager.chatCreateAt(widget.chat.createAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),

          // 메시지 버블
          GestureDetector(
            onLongPress: (){
              _chatAction(theme, isSender);
            },
            child: Builder(builder: (context) {
              if (widget.chat.type == ChatType.text) {
                return Column(
                  crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if(widget.chat.reply != null)...[
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: ReplyBubble(isMe: isSender, chat: widget.chat)),
                      SizedBox(height: 4.h,),
                    ],
                    TextChatBubble(
                      animation: now.difference(widget.chat.createAt).inSeconds < 3,
                      text: widget.chat.contents ?? '알수없는 채팅',
                      isSender: isSender,
                      tail: widget.tail,
                    ),
                  ],
                );
              } else if (widget.chat.type == ChatType.schedule) {
                if (widget.chat.scheduleId == null) {
                  return RemovedChatBubble(
                    isSender: isSender,
                    tail: widget.tail,
                  );
                } else {
                  return ScheduleChatBubble(
                    animation: now.difference(widget.chat.createAt).inSeconds < 3,
                    title: widget.chat.title ?? '',
                    startDate: widget.chat.startDate ?? DateTime(1999),
                    endDate: widget.chat.endDate ?? DateTime(1888),
                    tag: widget.chat.tag,
                    isSender: isSender,
                    tail: widget.tail,
                    scheduleId: widget.chat.scheduleId!,
                  );
                }
              } else if (widget.chat.type == ChatType.image) {
                return ImageChatBubble(chat: widget.chat, isMe: isSender);
              } else if (widget.chat.type == ChatType.removed) {
                return RemovedChatBubble(
                  isSender: isSender,
                  tail: widget.tail,
                );
              } else {
                return Container();
              }
            }),
          )
        ],
      );
    }
    // 수신자 메시지 (왼쪽 정렬)
    else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 12,),
          // 발신자 프로필 이미지 (있으면 표시)
          if (widget.tail)
            NadalProfileFrame(imageUrl: widget.chat.profileImage,)
          else
            const SizedBox(width: 36),

          // 발신자 이름 및 메시지 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 발신자 이름 (꼬리가 있는 경우 = 연속 메시지가 아닌 경우)
                if (widget.tail)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 4),
                    child: Text(
                      widget.chat.name!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // 메시지 버블 및 시간 영역
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 메시지 버블
                    GestureDetector(
                      onLongPress: (){
                          _chatAction(theme, isSender);
                      },
                      child: Builder(builder: (context) {
                        if (widget.chat.type == ChatType.text) {
                          return TextChatBubble(
                            animation: now.difference(widget.chat.createAt).inSeconds < 3,
                            text: widget.chat.contents ?? '알수없는 채팅',
                            isSender: isSender,
                            tail: widget.tail,
                          );
                        } else if (widget.chat.type == ChatType.schedule) {
                          if (widget.chat.scheduleId == null) {
                            return RemovedChatBubble(
                              isSender: isSender,
                              tail: widget.tail,
                            );
                          } else {
                            return ScheduleChatBubble(
                              animation: now.difference(widget.chat.createAt).inSeconds < 3,
                              title: widget.chat.title ?? '',
                              startDate: widget.chat.startDate ?? DateTime(1999),
                              endDate: widget.chat.endDate ?? DateTime(1888),
                              tag: widget.chat.tag,
                              isSender: isSender,
                              tail: widget.tail,
                              scheduleId: widget.chat.scheduleId!,
                            );
                          }
                        } else if (widget.chat.type == ChatType.image) {
                          // 이미지 채팅 처리 (필요시 구현)
                          return Container();
                        } else if (widget.chat.type == ChatType.removed) {
                          return RemovedChatBubble(
                            isSender: isSender,
                            tail: widget.tail,
                          );
                        } else {
                          return Container();
                        }
                      }),
                    ),

                    // 시간 표시
                    if (widget.timeVisible)
                      Container(
                        margin: const EdgeInsets.only(left: 6, bottom: 4, right: 6),
                        child: Text(
                          TextFormManager.chatCreateAt(widget.chat.createAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                    // 읽음 표시
                    if (widget.read != 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4, right: 6),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.read > 99 ? "99+" : widget.read}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}