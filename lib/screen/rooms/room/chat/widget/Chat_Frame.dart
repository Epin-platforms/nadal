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

class ChatFrame extends StatelessWidget {
  const ChatFrame({
    super.key,
    required this.chat,
    required this.timeVisible,
    required this.tail,
    required this.read,
    required this.index,
    required this.roomProvider,
  });

  final Chat chat;
  final bool timeVisible;
  final bool tail;
  final int read;
  final int index;
  final RoomProvider roomProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 안전한 사용자 확인
    final user = context.read<UserProvider>().user;
    final isSender = user != null && (chat.uid == user['uid']);

    return RepaintBoundary(
      child: isSender
          ? _buildSenderMessage(theme, colorScheme)
          : _buildReceiverMessage(theme, colorScheme),
    );
  }

  // 발신자 메시지 (오른쪽 정렬)
  Widget _buildSenderMessage(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 읽음 표시
        if (read > 0) _buildReadIndicator(colorScheme, theme),

        // 시간 표시
        if (timeVisible) _buildTimeDisplay(theme, colorScheme),

        // 메시지 버블
        _buildMessageBubble(true, theme),
      ],
    );
  }

  // 수신자 메시지 (왼쪽 정렬)
  Widget _buildReceiverMessage(ThemeData theme, ColorScheme colorScheme) {
    return Row(
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
              if (tail && chat.name != null) _buildSenderName(theme, colorScheme),

              // 메시지 버블 및 시간 영역
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 메시지 버블
                  _buildMessageBubble(false, theme),

                  // 시간 표시
                  if (timeVisible) _buildTimeDisplay(theme, colorScheme),

                  // 읽음 표시
                  if (read > 0) _buildReadIndicator(colorScheme, theme),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 읽음 표시
  Widget _buildReadIndicator(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(right: 4.w, bottom: 4.h),
      padding: EdgeInsets.all(2.r),
      constraints: BoxConstraints(minWidth: 18.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        read > 99 ? "99+" : read.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 시간 표시
  Widget _buildTimeDisplay(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(right: 6.w, bottom: 4.h, left: 6.w),
      child: Text(
        TextFormManager.chatCreateAt(chat.createAt),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // 발신자 프로필
  Widget _buildSenderProfile() {
    return tail
        ? GestureDetector(
      onTap: () => AppRoute.context?.push('/user/${chat.uid}'),
      child: NadalProfileFrame(imageUrl: chat.profileImage, size: 36.r),
    )
        : SizedBox(width: 36.r);
  }

  // 발신자 이름
  Widget _buildSenderName(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(left: 14.w, bottom: 4.h),
      child: Text(
        chat.name!,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 메시지 버블
  Widget _buildMessageBubble(bool isSender, ThemeData theme) {
    return GestureDetector(
      onLongPress: () => _showChatActions(theme, isSender),
      child: _buildBubbleContent(isSender, theme),
    );
  }

  // 버블 내용
  Widget _buildBubbleContent(bool isSender, ThemeData theme) {
    final now = DateTime.now();
    final isRecentMessage = now.difference(chat.createAt).inSeconds < 3;

    switch (chat.type) {
      case ChatType.text:
        return _buildTextBubble(isSender, isRecentMessage);

      case ChatType.schedule:
        return _buildScheduleBubble(isSender, isRecentMessage);

      case ChatType.image:
        return ImageChatBubble(chat: chat, isMe: isSender);

      case ChatType.removed:
        return RemovedChatBubble(isSender: isSender, tail: tail);
    }
  }

  // 텍스트 버블
  Widget _buildTextBubble(bool isSender, bool isRecentMessage) {
    return Column(
      crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (chat.reply != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ReplyBubble(isMe: isSender, chat: chat),
          ),
          SizedBox(height: 4.h),
        ],
        TextChatBubble(
          animation: isRecentMessage,
          text: chat.contents ?? '알수없는 채팅',
          isSender: isSender,
          tail: tail,
        ),
      ],
    );
  }

  // 스케줄 버블
  Widget _buildScheduleBubble(bool isSender, bool isRecentMessage) {
    if (chat.scheduleId == null) {
      return RemovedChatBubble(isSender: isSender, tail: tail);
    }

    return ScheduleChatBubble(
      animation: isRecentMessage,
      title: chat.title ?? '',
      startDate: chat.startDate ?? DateTime(1999),
      endDate: chat.endDate ?? DateTime(1888),
      tag: chat.tag,
      isSender: isSender,
      tail: tail,
      scheduleId: chat.scheduleId!,
    );
  }

  // 채팅 액션 메뉴 표시
  void _showChatActions(ThemeData theme, bool isSender) {
    if (chat.type == ChatType.removed) return;

    final context = AppRoute.context;
    if (context == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final nav = Navigator.of(context);

        return NadalSheet(
          actions: [
            // 복사 (텍스트만)
            if (chat.type == ChatType.text)
              CupertinoActionSheetAction(
                onPressed: () {
                  nav.pop();
                  Clipboard.setData(ClipboardData(text: chat.contents ?? ''));
                },
                child: Text(
                  '복사',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.secondaryHeaderColor,
                  ),
                ),
              ),

            // 답장
            CupertinoActionSheetAction(
              onPressed: () {
                nav.pop();
                roomProvider.setReply(chat.chatId);
              },
              child: Text(
                '답장',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.secondaryHeaderColor,
                ),
              ),
            ),

            // 신고 (본인 메시지가 아닌 경우)
            if (!isSender)
              CupertinoActionSheetAction(
                onPressed: () {
                  nav.pop();
                  context.push('/report?targetId=${chat.chatId}&type=chat');
                },
                child: Text(
                  '신고',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.secondaryHeaderColor,
                  ),
                ),
              ),

            // 삭제 (본인 메시지만)
            if (isSender)
              CupertinoActionSheetAction(
                onPressed: () async {
                  nav.pop();
                  await _deleteChat();
                },
                child: Text(
                  '삭제',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.secondaryHeaderColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 채팅 삭제
  Future<void> _deleteChat() async {
    try {
      await serverManager.put(
          'chat/remove/${chat.chatId}?roomId=${chat.roomId}'
      );
    } catch (e) {
      print('❌ 채팅 삭제 오류: $e');
    }
  }
}