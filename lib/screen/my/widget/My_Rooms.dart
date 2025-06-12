import 'package:flutter/cupertino.dart';
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
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더는 동일
          _buildHeader(context),

          // 로딩 상태 개선
          if(_shouldShowLoading(roomsProvider, chatProvider))
            _buildLoadingList()
          else if(_hasRooms(roomsProvider))
            _buildRoomsList(roomsProvider, chatProvider, context)
          else
            _buildEmptyState(context)
        ],
      ),
    );
  }

  // 로딩 상태 판단 로직 개선
  bool _shouldShowLoading(RoomsProvider roomsProvider, ChatProvider chatProvider) {
    return roomsProvider.rooms == null ||
        chatProvider.socketLoading ||
        !chatProvider.isInitialized;
  }

  bool _hasRooms(RoomsProvider roomsProvider) {
    return roomsProvider.rooms != null && roomsProvider.rooms!.isNotEmpty;
  }

  Widget _buildRoomsList(RoomsProvider roomsProvider, ChatProvider chatProvider, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: roomsProvider.getRoomsList(context).length,
      itemBuilder: (context, index) {
        final roomEntry = roomsProvider.getRoomsList(context)[index];
        final roomData = roomEntry.value;
        final roomId = roomData['roomId'];

        // 안전한 데이터 접근
        final unread = chatProvider.my[roomId]?['unreadCount'];
        final lastChatText = _getLastChatSafely(chatProvider, roomId);

        return ListTile(
          onTap: () => context.push('/room/$roomId'),
          leading: NadalRoomFrame(imageUrl: roomData['roomImage']),
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
                        text: '(${roomData['memberCount'] ?? 0})',
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
            constraints: BoxConstraints(maxHeight: 24.h),
            child: Text(
              lastChatText,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          trailing: unread != null && unread != 0
              ? NadalRoomNotReadTag(number: unread)
              : null,
        );
      },
    );
  }

  // 안전한 마지막 채팅 텍스트 가져오기
  String _getLastChatSafely(ChatProvider chatProvider, int roomId) {
    try {
      final chats = chatProvider.chat[roomId];
      if (chats == null || chats.isEmpty) {
        return '아직 채팅이 없어요';
      }
      return chatProvider.getLastChat(roomId);
    } catch (e) {
      print('getLastChat 오류 (roomId: $roomId): $e');
      return '채팅을 불러오는 중...';
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, bottom: 16.h, right: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('MY 클럽', style: Theme.of(context).textTheme.titleLarge),
          Row(
            children: [
              NadalIconButton(
                onTap: () => context.push('/searchRoom'),
                icon: CupertinoIcons.search,
              ),
              SizedBox(width: 8.w),
              NadalIconButton(
                onTap: () => context.push('/createRoom'),
                image: 'assets/image/icon/chat_add.png',
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: NadalProfileFrame(isPlaceHolder: true),
          title: NadalPlaceholderContainer(height: 18.h),
          subtitle: NadalPlaceholderContainer(height: 15.h, width: 100.w),
        );
      },
      separatorBuilder: (context, index) => Divider(),
      itemCount: 3,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 300.h,
      child: NadalEmptyList(
        title: '아직 참여한 클럽이 없어요',
        subtitle: '근처 클럽을 찾아보거나, 새로운 클럽을 만들어보세요',
        onAction: () => GoRouter.of(context).push('/searchRoom'),
        icon: Icon(CupertinoIcons.search, color: Theme.of(context).colorScheme.onPrimary),
        actionText: '클럽 둘러보기',
      ),
    );
  }
}