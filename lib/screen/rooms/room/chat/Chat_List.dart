import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Image_Chat_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Chat_Frame.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Date_Divider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Log_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';
import '../../../../model/room/Room_Log.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key, required this.roomProvider});
  final RoomProvider roomProvider;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ScrollController _scrollController = ScrollController();

  bool _hasMoreBefore = true;  // 이전 채팅이 더 있는지
  bool _hasMoreAfter = false;  // 이후 채팅이 더 있는지
  bool _isLoading = false;     // 로딩 중인지

  Timer? _scrollDebouncer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 초기 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebouncer?.cancel();
    super.dispose();
  }

  // 초기 스크롤 위치 설정
  void _initializeScrollPosition() {
    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    final chatProvider = context.read<ChatProvider>();
    final chats = chatProvider.chat[roomId] ?? [];
    final myData = chatProvider.my[roomId];

    if (chats.isEmpty) {
      _hasMoreBefore = false;
      _hasMoreAfter = false;
      return;
    }

    // 초기 hasMore 설정
    _hasMoreBefore = chats.length >= 20;

    final lastRead = myData?['lastRead'] as int? ?? 0;
    final unreadCount = chats.where((c) => c.chatId > lastRead).length;
    _hasMoreAfter = unreadCount >= 50;

    print('📊 초기 설정: before=$_hasMoreBefore, after=$_hasMoreAfter, 채팅수=${chats.length}, 안읽은수=$unreadCount');
  }

  // 스크롤 이벤트 처리
  void _onScroll() {
    if (_isLoading) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent < 100.h) return;

    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // reverse ListView에서 위로 스크롤 = 이전 채팅 로드
      if (position.pixels >= position.maxScrollExtent - 200.h && _hasMoreBefore) {
        _loadMoreBefore();
      }

      // reverse ListView에서 아래로 스크롤 = 이후 채팅 로드
      if (position.pixels <= 200.h && _hasMoreAfter) {
        _loadMoreAfter();
      }
    });
  }

  // 이전 채팅 로드
  Future<void> _loadMoreBefore() async {
    if (_isLoading) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    setState(() => _isLoading = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      final hasMore = await chatProvider.loadChatsBefore(roomId);

      if (mounted) {
        setState(() => _hasMoreBefore = hasMore);
      }
    } catch (e) {
      print('❌ 이전 채팅 로드 오류: $e');
      if (mounted) {
        setState(() => _hasMoreBefore = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 이후 채팅 로드
  Future<void> _loadMoreAfter() async {
    if (_isLoading) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    setState(() => _isLoading = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      final hasMore = await chatProvider.loadChatsAfter(roomId);

      if (mounted) {
        setState(() => _hasMoreAfter = hasMore);
      }
    } catch (e) {
      print('❌ 이후 채팅 로드 오류: $e');
      if (mounted) {
        setState(() => _hasMoreAfter = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 채팅과 로그 합쳐서 정렬된 리스트 생성
  List<dynamic> _buildCombinedList() {
    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return [];

    final chatProvider = context.read<ChatProvider>();
    final chats = chatProvider.chat[roomId] ?? [];
    final roomLogs = widget.roomProvider.roomLog;

    if (chats.isEmpty && roomLogs.isEmpty) return [];
    if (chats.isEmpty) return roomLogs.cast<dynamic>();

    // 채팅 날짜 범위에 해당하는 로그만 필터링
    final chatDates = chats.map((chat) => chat.createAt).toList();
    if (chatDates.isEmpty) return chats.cast<dynamic>();

    final oldestDate = chatDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestDate = chatDates.reduce((a, b) => a.isAfter(b) ? a : b);

    final filteredLogs = roomLogs.where((log) {
      return log.createAt.isAfter(oldestDate.subtract(const Duration(hours: 1))) &&
          log.createAt.isBefore(newestDate.add(const Duration(hours: 1)));
    }).toList();

    // 채팅과 로그 합치기
    final combinedList = <dynamic>[...chats, ...filteredLogs];

    // 시간순 정렬 (최신이 먼저)
    combinedList.sort((a, b) {
      final aDate = a is Chat ? a.createAt : (a as RoomLog).createAt;
      final bDate = b is Chat ? b.createAt : (b as RoomLog).createAt;
      return bDate.compareTo(aDate);
    });

    return combinedList;
  }

  // 날짜 구분선 표시 여부 확인
  bool _shouldShowDateDivider(dynamic item, int index, List<dynamic> list) {
    if (index == list.length - 1) return true;

    final currentDate = item is Chat ? item.createAt : (item as RoomLog).createAt;
    final currentDay = DateTime(currentDate.year, currentDate.month, currentDate.day);

    final nextItem = list[index + 1];
    final nextDate = nextItem is Chat ? nextItem.createAt : (nextItem as RoomLog).createAt;
    final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return currentDay != nextDay;
  }

  // 채팅 아이템 빌드
  Widget _buildChatItem(Chat chat, int index, List<dynamic> list) {
    // 이전/다음 채팅 참조
    Chat? previousChat;
    Chat? nextChat;

    if (index < list.length - 1 && list[index + 1] is Chat) {
      previousChat = list[index + 1] as Chat;
    }
    if (index > 0 && list[index - 1] is Chat) {
      nextChat = list[index - 1] as Chat;
    }

    // 시간/꼬리 표시 여부
    final timeVisible = nextChat == null ||
        nextChat.uid != chat.uid ||
        nextChat.createAt.difference(chat.createAt).inMinutes > 5;

    final tail = previousChat == null ||
        previousChat.uid != chat.uid ||
        chat.createAt.difference(previousChat.createAt).inMinutes > 5;

    // 읽음 표시 계산
    int readCount = 0;
    final roomMembers = widget.roomProvider.roomMembers;
    if (roomMembers.isNotEmpty) {
      final totalMembers = roomMembers.keys.length;
      final readMembers = roomMembers.values
          .where((e) => (e['lastRead'] as int? ?? 0) >= chat.chatId)
          .length;
      readCount = totalMembers - readMembers;
    }

    return Column(
      children: [
        if (_shouldShowDateDivider(chat, index, list))
          DateDivider(date: chat.createAt),

        ChatFrame(
          chat: chat,
          timeVisible: timeVisible,
          tail: tail,
          read: readCount,
          index: index,
          roomProvider: widget.roomProvider,
        ),
      ],
    );
  }

  // 로그 아이템 빌드
  Widget _buildLogItem(RoomLog roomLog, int index, List<dynamic> list) {
    return Column(
      children: [
        if (_shouldShowDateDivider(roomLog, index, list))
          DateDivider(date: roomLog.createAt),

        LogFrame(roomLog: roomLog),
      ],
    );
  }

  // 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(child: NadalCircular(size: 30.r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final combinedList = _buildCombinedList();

              if (combinedList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      '아직 채팅이 없어요\n첫 메시지를 보내보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              // 로딩 인디케이터 포함한 아이템 개수 계산
              final totalCount = combinedList.length +
                  (_hasMoreAfter ? 1 : 0) +
                  (_hasMoreBefore ? 1 : 0);

              return ListView.separated(
                controller: _scrollController,
                reverse: true,
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  // 하단 로딩 인디케이터 (reverse에서는 상단)
                  if (_hasMoreAfter && index == 0) {
                    return _buildLoadingIndicator();
                  }

                  // 상단 로딩 인디케이터 (reverse에서는 하단)
                  final bottomLoadingIndex = combinedList.length + (_hasMoreAfter ? 1 : 0);
                  if (_hasMoreBefore && index == bottomLoadingIndex) {
                    return _buildLoadingIndicator();
                  }

                  // 실제 아이템
                  final actualIndex = index - (_hasMoreAfter ? 1 : 0);
                  if (actualIndex < 0 || actualIndex >= combinedList.length) {
                    return const SizedBox.shrink();
                  }

                  final item = combinedList[actualIndex];

                  if (item is Chat) {
                    return _buildChatItem(item, actualIndex, combinedList);
                  } else if (item is RoomLog) {
                    return _buildLogItem(item, actualIndex, combinedList);
                  }

                  return const SizedBox.shrink();
                },
                separatorBuilder: (context, index) => SizedBox(height: 4.h),
              );
            },
          ),
        ),

        // 전송 중인 이미지 표시
        Consumer<RoomProvider>(
          builder: (context, roomProvider, child) {
            if (roomProvider.sendingImage.isNotEmpty) {
              return Column(
                children: [
                  SizedBox(height: 8.h),
                  SendingImagesPlaceHolder(images: roomProvider.sendingImage),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}