import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/widget/Nadal_PlaceHolder_Container.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_NotRead_Tag.dart';

import '../../../manager/project/Import_Manager.dart';
import '../../../widget/Nadal_Room_Frame.dart';

class MyRooms extends StatefulWidget {
  const MyRooms({super.key});

  @override
  State<MyRooms> createState() => _MyRoomsState();
}

class _MyRoomsState extends State<MyRooms> {
  // 🔧 상태 관리 개선
  bool _hasCheckedInitialState = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // 🔧 초기 상태 확인
  void _checkInitialState() {
    if (!mounted) return;

    final roomsProvider = context.read<RoomsProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (_isDataReady(roomsProvider, chatProvider)) {
      setState(() => _hasCheckedInitialState = true);
    } else {
      _scheduleRetry();
    }
  }

  // 🔧 재시도 스케줄링
  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      print('❌ 최대 재시도 횟수 초과 - 강제로 로딩 완료 처리');
      setState(() => _hasCheckedInitialState = true);
      return;
    }

    _retryTimer?.cancel();
    _retryCount++;

    final delay = Duration(milliseconds: 500 * _retryCount);
    print('🔄 ${delay.inMilliseconds}ms 후 데이터 준비 상태 재확인 ($_retryCount/$_maxRetries)');

    _retryTimer = Timer(delay, () {
      if (mounted) {
        _checkInitialState();
      }
    });
  }

  // 🔧 간소화된 데이터 준비 상태 확인
  bool _isDataReady(RoomsProvider roomsProvider, ChatProvider chatProvider) {
    // 1. 기본 초기화 확인
    if (!chatProvider.isInitialized) {
      print('🔄 ChatProvider 초기화 중');
      return false;
    }

    // 2. 소켓 로딩 확인
    if (chatProvider.socketLoading) {
      print('🔄 소켓 로딩 중');
      return false;
    }

    // 3. 방 목록 확인
    if (roomsProvider.rooms == null) {
      print('🔄 방 목록 로딩 중');
      return false;
    }

    // 4. 방이 있다면 최소한의 데이터 확인
    if (roomsProvider.rooms!.isNotEmpty) {
      final readyRooms = roomsProvider.rooms!.keys.where((roomId) {
        return chatProvider.isRoomDataReady(roomId);
      }).length;

      final totalRooms = roomsProvider.rooms!.length;
      final readyPercentage = readyRooms / totalRooms;

      print('📊 방 준비 상태: $readyRooms/$totalRooms (${(readyPercentage * 100).toInt()}%)');

      // 🔧 조건 완화: 70% 이상 또는 최소 3개 방이 준비되면 OK
      if (readyPercentage >= 0.7 || (readyRooms >= 3 && totalRooms > 3)) {
        return true;
      }

      // 🔧 5초 이상 기다렸다면 강제로 완료 처리
      if (_retryCount >= 10) {
        print('⏰ 타임아웃 - 현재 상태로 진행');
        return true;
      }

      return false;
    }

    // 방이 없으면 준비 완료
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer2<RoomsProvider, ChatProvider>(
      builder: (context, roomsProvider, chatProvider, child) {
        // 🔧 로딩 상태 확인 개선
        if (!_hasCheckedInitialState || _shouldShowLoading(roomsProvider, chatProvider)) {
          return _buildLoadingList();
        }

        if (_hasRooms(roomsProvider)) {
          return _buildRoomsList(roomsProvider, chatProvider, context);
        }

        return _buildEmptyState(context);
      },
    );
  }

  // 🔧 단순화된 로딩 상태 확인
  bool _shouldShowLoading(RoomsProvider roomsProvider, ChatProvider chatProvider) {
    // 초기 상태 확인이 완료되지 않았으면 로딩
    if (!_hasCheckedInitialState) return true;

    // 재연결 중이면 로딩 표시하지 않음 (데이터는 있으니까)
    if (chatProvider.socketLoading && roomsProvider.rooms != null && roomsProvider.rooms!.isNotEmpty) {
      return false;
    }

    // 완전히 새로 로딩하는 경우만 로딩 표시
    return roomsProvider.rooms == null || (!chatProvider.isInitialized && roomsProvider.rooms!.isEmpty);
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

        return _buildRoomItem(roomId, roomData, chatProvider);
      },
    );
  }

  // 🔧 방 아이템 위젯 분리
  Widget _buildRoomItem(int roomId, Map roomData, ChatProvider chatProvider) {
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
          _getLastChatSafely(chatProvider, roomId),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
      trailing: _buildTrailing(chatProvider, roomId),
    );
  }

  // 🔧 trailing 위젯 분리
  Widget? _buildTrailing(ChatProvider chatProvider, int roomId) {
    final unread = _getUnreadCountSafely(chatProvider, roomId);

    if (unread > 0) {
      return NadalRoomNotReadTag(number: unread);
    }

    // 🔧 재연결 중인 방 표시
    if (chatProvider.socketLoading && !chatProvider.isRoomDataReady(roomId)) {
      return SizedBox(
        width: 16.w,
        height: 16.h,
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return null;
  }

  // 🔧 안전한 방 목록 가져오기
  List<MapEntry<int, Map>> _getSafeRoomsList(RoomsProvider roomsProvider, BuildContext context) {
    try {
      return roomsProvider.getRoomsList(context);
    } catch (e) {
      print('getRoomsList 오류: $e');
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
      if (myData == null) return 0;
      return myData['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('getUnreadCount 오류 (roomId: $roomId): $e');
      return 0;
    }
  }

  // 🔧 안전한 마지막 채팅 텍스트 가져오기
  String _getLastChatSafely(ChatProvider chatProvider, int roomId) {
    try {
      if (!chatProvider.isJoined(roomId)) {
        return '연결 중...';
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