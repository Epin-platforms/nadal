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

  // 🔧 로딩 상태 판단 로직 대폭 개선
  bool _shouldShowLoading(RoomsProvider roomsProvider, ChatProvider chatProvider) {
    // 1. RoomsProvider가 아직 초기화되지 않음
    if (roomsProvider.rooms == null) {
      print('🔄 rooms가 null - 로딩 중');
      return true;
    }

    // 2. 소켓이 아직 로딩 중
    if (chatProvider.socketLoading) {
      print('🔄 소켓 로딩 중');
      return true;
    }

    // 3. rooms가 있는데 ChatProvider에 데이터가 준비되지 않음
    if (roomsProvider.rooms!.isNotEmpty) {
      final isDataReady = _isAllRoomsDataReady(roomsProvider.rooms!, chatProvider);
      if (!isDataReady) {
        print('🔄 채팅 데이터 준비 중');
        return true;
      }
    }

    print('✅ 모든 데이터 준비 완료');
    return false;
  }

  // 🔧 새로운 메서드: 모든 방의 데이터가 준비되었는지 확인
  bool _isAllRoomsDataReady(Map<int, Map> rooms, ChatProvider chatProvider) {
    // rooms가 비어있으면 준비된 것으로 간주
    if (rooms.isEmpty) return true;

    // 모든 방에 대해 기본 데이터가 있는지 확인 (전부 조인될 필요는 없음)
    final totalRooms = rooms.length;
    final joinedRooms = rooms.keys.where((roomId) =>
    chatProvider.isJoined(roomId) && chatProvider.my[roomId] != null
    ).length;

    // 최소 50% 이상의 방이 준비되었으면 로딩 완료로 간주
    final readyPercentage = joinedRooms / totalRooms;
    final isReady = readyPercentage >= 0.5;

    print('📊 방 준비 상태: $joinedRooms/$totalRooms (${(readyPercentage * 100).toInt()}%)');
    return isReady;
  }

  bool _hasRooms(RoomsProvider roomsProvider) {
    return roomsProvider.rooms != null && roomsProvider.rooms!.isNotEmpty;
  }

  Widget _buildRoomsList(RoomsProvider roomsProvider, ChatProvider chatProvider, BuildContext context) {
    final roomsList = _getSafeRoomsList(roomsProvider, context);

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: roomsList.length,
      itemBuilder: (context, index) {
        final roomEntry = roomsList[index];
        final roomData = roomEntry.value;
        final roomId = roomData['roomId'] as int;

        // 안전한 데이터 접근
        final unread = _getUnreadCountSafely(chatProvider, roomId);
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
                    text: roomData['roomName']?.toString() ?? '알 수 없는 방',
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
          trailing: unread > 0
              ? NadalRoomNotReadTag(number: unread)
              : null,
        );
      },
    );
  }

  // 🔧 안전한 방 목록 가져오기
  List<MapEntry<int, Map>> _getSafeRoomsList(RoomsProvider roomsProvider, BuildContext context) {
    try {
      return roomsProvider.getRoomsList(context);
    } catch (e) {
      print('getRoomsList 오류: $e');
      // 에러 시 rooms를 직접 변환하여 반환
      final rooms = roomsProvider.rooms;
      if (rooms != null) {
        return rooms.entries.toList();
      }
      return [];
    }
  }

  // 🔧 안전한 unread 카운트 가져오기
  int _getUnreadCountSafely(ChatProvider chatProvider, int roomId) {
    try {
      final myData = chatProvider.my[roomId];
      if (myData == null) {
        // 데이터가 없으면 0 반환 (로딩 중일 수 있음)
        return 0;
      }
      return myData['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('getUnreadCount 오류 (roomId: $roomId): $e');
      return 0;
    }
  }

  // 🔧 안전한 마지막 채팅 텍스트 가져오기
  String _getLastChatSafely(ChatProvider chatProvider, int roomId) {
    try {
      // 조인되지 않은 방은 "참가 중..." 표시
      if (!chatProvider.isJoined(roomId)) {
        return '참가 중...';
      }

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