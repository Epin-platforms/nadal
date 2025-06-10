import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
            if(widget.chat.type == ChatType.text)
            CupertinoActionSheetAction(
                onPressed: (){
                  nav.pop();
                  Clipboard.setData(ClipboardData(text: widget.chat.contents ?? ''));
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


  // Chat_Frame.dart의 build 메서드에서 다음 부분을 수정:

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 안전한 사용자 확인
    final user = context.read<UserProvider>().user;
    final isSender = user != null && (widget.chat.uid == user['uid']);

    // 발신자 메시지 (오른쪽 정렬)
    if (isSender) {
      return _buildSenderMessage(theme, colorScheme, now);
    }
    // 수신자 메시지 (왼쪽 정렬)
    else {
      return _buildReceiverMessage(theme, colorScheme, now);
    }
  }


  Widget _buildSenderMessage(ThemeData theme, ColorScheme colorScheme, DateTime now) {
    return RepaintBoundary( // 렌더링 최적화
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 읽음 표시
          if (widget.read > 0)
            _buildReadIndicator(colorScheme, theme, widget.read),

          // 시간 표시
          if (widget.timeVisible)
            _buildTimeDisplay(theme, colorScheme),

          // 메시지 버블
          _buildMessageBubble(true, theme, now),
        ],
      ),
    );
  }

  Widget _buildReceiverMessage(ThemeData theme, ColorScheme colorScheme, DateTime now) {
    return RepaintBoundary( // 렌더링 최적화
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 12.w),
          // 발신자 프로필 이미지
          _buildSenderProfile(),

          // 발신자 이름 및 메시지 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 발신자 이름
                if (widget.tail && widget.chat.name != null)
                  _buildSenderName(theme, colorScheme),

                // 메시지 버블 및 시간 영역
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 메시지 버블
                    _buildMessageBubble(false, theme, now),

                    // 시간 표시
                    if (widget.timeVisible)
                      _buildTimeDisplay(theme, colorScheme),

                    // 읽음 표시
                    if (widget.read > 0)
                      _buildReadIndicator(colorScheme, theme, widget.read),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadIndicator(ColorScheme colorScheme, ThemeData theme, int readCount) {
    return Container(
      margin: EdgeInsets.only(right: 4.w, bottom: 4.h),
      padding: EdgeInsets.all(2.r),
      constraints: BoxConstraints(minWidth: 18.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${readCount > 99 ? "99+" : readCount}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeDisplay(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(right: 6.w, bottom: 4.h, left: 6.w),
      child: Text(
        TextFormManager.chatCreateAt(widget.chat.createAt),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildSenderProfile() {
    return widget.tail
        ? GestureDetector(
      onTap: () => context.push('/user/${widget.chat.uid}'),
      child: NadalProfileFrame(imageUrl: widget.chat.profileImage, size: 36.r),
    )
        : SizedBox(width: 36.r);
  }

  Widget _buildSenderName(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(left: 14.w, bottom: 4.h),
      child: Text(
        widget.chat.name!,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(bool isSender, ThemeData theme, DateTime now) {
    return GestureDetector(
      onLongPress: () => _chatAction(theme, isSender),
      child: _buildBubbleContent(isSender, theme, now),
    );
  }

  Widget _buildBubbleContent(bool isSender, ThemeData theme, DateTime now) {
    switch (widget.chat.type) {
      case ChatType.text:
        return _buildTextBubble(isSender, now);

      case ChatType.schedule:
        return _buildScheduleBubble(isSender, now);

      case ChatType.image:
        return ImageChatBubble(chat: widget.chat, isMe: isSender);

      case ChatType.removed:
        return RemovedChatBubble(isSender: isSender, tail: widget.tail);
    }
  }

  Widget _buildTextBubble(bool isSender, DateTime now) {
    return Column(
      crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.chat.reply != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ReplyBubble(isMe: isSender, chat: widget.chat),
          ),
          SizedBox(height: 4.h),
        ],
        TextChatBubble(
          animation: now.difference(widget.chat.createAt).inSeconds < 3,
          text: widget.chat.contents ?? '알수없는 채팅',
          isSender: isSender,
          tail: widget.tail,
        ),
      ],
    );
  }

  Widget _buildScheduleBubble(bool isSender, DateTime now) {
    if (widget.chat.scheduleId == null) {
      return RemovedChatBubble(isSender: isSender, tail: widget.tail);
    }

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
}