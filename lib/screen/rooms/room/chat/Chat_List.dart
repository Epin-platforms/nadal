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
  final Map<int, GlobalKey> _chatKeys = {};

  bool _isInitialized = false;
  bool _hasMoreBefore = false;
  bool _hasMoreAfter = false;
  bool _isLoadingBefore = false;
  bool _isLoadingAfter = false;

  int? _lastReadChatId;
  Timer? _scrollDebouncer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebouncer?.cancel();
    _chatKeys.clear();
    super.dispose();
  }

  ChatProvider get chatProvider => context.read<ChatProvider>();

  void _onScroll() {
    if (_isLoadingBefore || _isLoadingAfter || chatProvider.socketLoading) {
      print('스크롤 무시: loading=$_isLoadingBefore/$_isLoadingAfter, socket=${chatProvider.socketLoading}');
      return;
    }

    final position = _scrollController.position;

    // 스크롤 가능한 높이가 충분한지 체크 (무한 로딩 방지)
    if (position.maxScrollExtent < 100.h) {
      print('스크롤 무시: 높이 부족 (${position.maxScrollExtent.toInt()}h < 100h)');
      return;
    }

    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      print('📍 스크롤: ${position.pixels.toInt()}/${position.maxScrollExtent.toInt()}');
      print('📍 hasMore: before=$_hasMoreBefore, after=$_hasMoreAfter');

      // reverse ListView: 위로 스크롤 = 이전 채팅 로드 (maxScrollExtent 근처)
      if (position.pixels >= position.maxScrollExtent - 200.h && _hasMoreBefore) {
        print('✅ 이전 채팅 로드 트리거');
        _loadMoreBefore();
      }

      // reverse ListView: 아래로 스크롤 = 이후 채팅 로드 (0 근처)
      if (position.pixels <= 200.h && _hasMoreAfter) {
        print('✅ 이후 채팅 로드 트리거');
        _loadMoreAfter();
      }
    });
  }

  Future<void> _loadMoreBefore() async {
    if (_isLoadingBefore) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    setState(() => _isLoadingBefore = true);

    try {
      print('🔄 이전 채팅 로드 시작');
      final hasMore = await chatProvider.loadChatsBefore(roomId);
      print('✅ 이전 채팅 로드 완료: hasMore=$hasMore');

      if (mounted) {
        setState(() => _hasMoreBefore = hasMore);
        print('📊 _hasMoreBefore 업데이트: $_hasMoreBefore');
      }
    } catch (e) {
      print('❌ 이전 채팅 로드 오류: $e');
      if (mounted) {
        setState(() => _hasMoreBefore = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBefore = false);
      }
    }
  }

  Future<void> _loadMoreAfter() async {
    if (_isLoadingAfter) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    setState(() => _isLoadingAfter = true);

    try {
      print('🔄 이후 채팅 로드 시작');
      final hasMore = await chatProvider.loadChatsAfter(roomId);
      print('✅ 이후 채팅 로드 완료: hasMore=$hasMore');

      if (mounted) {
        setState(() => _hasMoreAfter = hasMore);
        print('📊 _hasMoreAfter 업데이트: $_hasMoreAfter');
      }
    } catch (e) {
      print('❌ 이후 채팅 로드 오류: $e');
      if (mounted) {
        setState(() => _hasMoreAfter = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAfter = false);
      }
    }
  }

  void _initializeIfNeeded() {
    if (_isInitialized) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    final chats = chatProvider.chat[roomId];
    if (chats == null) return;

    _isInitialized = true;
    _lastReadChatId = chatProvider.getLastReadChatId(roomId);

    print('🚀 채팅 리스트 초기화');
    print('- 채팅 수: ${chats.length}');
    print('- lastReadChatId: $_lastReadChatId');
    print('- 로그 수: ${widget.roomProvider.roomLog.length}');

    // hasMore 플래그 설정 - 더 엄격한 조건 적용
    if (chats.isEmpty) {
      _hasMoreBefore = false;
      _hasMoreAfter = false;
      print('- 채팅 없음: hasMoreBefore=false, hasMoreAfter=false');
    } else {
      // 초기 로딩에서 가져온 채팅이 60개 미만이고, 실제로 더 오래된 채팅이 있을 때만 true
      // 하지만 일단 한 번 로드를 시도해보고 결과에 따라 결정하는 것이 더 안전
      _hasMoreBefore = chats.length >= 20; // 20개 이상이면 더 있을 가능성

      // 안읽은 채팅 수 계산
      final unreadCount = _lastReadChatId != null
          ? chats.where((c) => c.chatId > _lastReadChatId!).length
          : chats.length;
      _hasMoreAfter = unreadCount >= 50;

      print('- hasMoreBefore: $_hasMoreBefore (채팅수: ${chats.length})');
      print('- hasMoreAfter: $_hasMoreAfter (안읽은수: $unreadCount)');
    }

    // lastRead 위치로 스크롤
    if (_lastReadChatId != null && _lastReadChatId! > 0 && chats.isNotEmpty) {
      final targetExists = chats.any((chat) => chat.chatId == _lastReadChatId);
      if (targetExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _scrollToLastRead();
          });
        });
      }
    }
  }

  void _scrollToLastRead() {
    if (_lastReadChatId == null) return;

    final key = _chatKeys[_lastReadChatId!];
    if (key?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      } catch (e) {
        print('스크롤 실패: $e');
      }
    }
  }

  GlobalKey? _getChatKey(int chatId) {
    if (!_chatKeys.containsKey(chatId)) {
      _chatKeys[chatId] = GlobalKey();
    }
    return _chatKeys[chatId];
  }

  List<dynamic> _buildChatList() {
    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) {
      print('❌ roomId가 null');
      return [];
    }

    final chats = chatProvider.chat[roomId] ?? [];
    final roomLogs = widget.roomProvider.roomLog;

    print('📊 리스트 빌드: 채팅=${chats.length}개, 로그=${roomLogs.length}개');

    // 채팅과 로그 모두 없으면 빈 리스트
    if (chats.isEmpty && roomLogs.isEmpty) {
      print('- 채팅과 로그 모두 없음');
      return [];
    }

    // 채팅이 없으면 로그만 반환
    if (chats.isEmpty) {
      print('- 채팅 없음, 로그만 반환: ${roomLogs.length}개');
      return roomLogs.cast<dynamic>();
    }

    // 채팅의 날짜 범위에 해당하는 로그만 필터링
    final chatDates = chats.map((chat) => chat.createAt).toList();
    final oldestDate = chatDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestDate = chatDates.reduce((a, b) => a.isAfter(b) ? a : b);

    final filteredLogs = roomLogs.where((log) {
      return log.createAt.isAfter(oldestDate.subtract(const Duration(hours: 1))) &&
          log.createAt.isBefore(newestDate.add(const Duration(hours: 1)));
    }).toList();

    print('- 필터링된 로그: ${filteredLogs.length}개');

    // 채팅과 로그 합치기
    final combinedList = <dynamic>[...chats, ...filteredLogs];

    // 시간순 정렬 (최신이 먼저)
    combinedList.sort((a, b) {
      final aDate = a is Chat ? a.createAt : (a as RoomLog).createAt;
      final bDate = b is Chat ? b.createAt : (b as RoomLog).createAt;
      return bDate.compareTo(aDate);
    });

    print('- 최종 리스트: ${combinedList.length}개');
    return combinedList;
  }

  bool _shouldShowLastReadDivider(Chat chat, int index, List<dynamic> chatList) {
    if (_lastReadChatId == null || chat.chatId != _lastReadChatId) return false;
    if (index >= chatList.length - 1) return false;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return false;

    final chats = chatProvider.chat[roomId] ?? [];
    final unreadCount = chats.where((c) => c.chatId > _lastReadChatId!).length;
    return unreadCount > 10;
  }

  Widget _buildDateDivider(DateTime date) {
    return DateDivider(
      key: ValueKey('date-${date.toIso8601String()}'),
      date: date,
    );
  }

  Widget _buildLastReadDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '여기까지 읽음',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11.sp,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, int index, List<dynamic> chatList) {
    // 이전/다음 채팅 참조
    Chat? previousChat;
    Chat? nextChat;

    if (index < chatList.length - 1 && chatList[index + 1] is Chat) {
      previousChat = chatList[index + 1] as Chat;
    }
    if (index > 0 && chatList[index - 1] is Chat) {
      nextChat = chatList[index - 1] as Chat;
    }

    // 날짜 구분선 표시 여부
    final currentDate = DateTime(chat.createAt.year, chat.createAt.month, chat.createAt.day);
    DateTime? previousDate;

    if (index < chatList.length - 1) {
      final prevItem = chatList[index + 1];
      final prevDate = prevItem is Chat ? prevItem.createAt : (prevItem as RoomLog).createAt;
      previousDate = DateTime(prevDate.year, prevDate.month, prevDate.day);
    }

    final showDate = (index == chatList.length - 1) || (currentDate != previousDate);

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
          .where((e) => (e['lastRead'] as int? ?? 0) > chat.chatId)
          .length;
      readCount = totalMembers - readMembers;
    }

    final showLastReadDivider = _shouldShowLastReadDivider(chat, index, chatList);
    final chatKey = chat.chatId == _lastReadChatId ? _getChatKey(chat.chatId) : null;

    return Column(
      children: [
        if (showDate) _buildDateDivider(currentDate),
        if (showLastReadDivider) _buildLastReadDivider(),
        Container(
          key: chatKey ?? ValueKey('chat-${chat.chatId}'),
          child: ChatFrame(
            chat: chat,
            timeVisible: timeVisible,
            tail: tail,
            read: readCount,
            index: index,
            roomProvider: widget.roomProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(RoomLog roomLog, int index, List<dynamic> chatList) {
    final currentDate = DateTime(roomLog.createAt.year, roomLog.createAt.month, roomLog.createAt.day);
    DateTime? previousDate;

    if (index < chatList.length - 1) {
      final prevItem = chatList[index + 1];
      final prevDate = prevItem is Chat ? prevItem.createAt : (prevItem as RoomLog).createAt;
      previousDate = DateTime(prevDate.year, prevDate.month, prevDate.day);
    }

    final showDate = (index == chatList.length - 1) || (currentDate != previousDate);

    return Column(
      children: [
        if (showDate) _buildDateDivider(currentDate),
        LogFrame(
          key: ValueKey('log-${roomLog.logId}'),
          roomLog: roomLog,
        ),
      ],
    );
  }

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
          child: Consumer2<ChatProvider, RoomProvider>(
            builder: (context, chatProvider, roomProvider, child) {
              _initializeIfNeeded();

              final chatList = _buildChatList();

              print('🏗️ 빌드: chatList=${chatList.length}개');
              print('🏗️ 현재 상태: hasMoreBefore=$_hasMoreBefore, hasMoreAfter=$_hasMoreAfter');
              print('🏗️ 로딩 상태: loadingBefore=$_isLoadingBefore, loadingAfter=$_isLoadingAfter');

              if (chatList.isEmpty) {
                print('🏗️ 빈 화면 표시');
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

              // 채팅이 있는 경우만 로딩 인디케이터 표시
              final roomId = roomProvider.room?['roomId'] as int?;
              final hasChats = roomId != null && (chatProvider.chat[roomId]?.isNotEmpty ?? false);

              print('🏗️ hasChats: $hasChats');
              print('🏗️ 로딩 인디케이터: before=${hasChats && _hasMoreBefore}, after=${hasChats && _hasMoreAfter}');

              final itemCount = chatList.length +
                  (hasChats && _hasMoreAfter ? 1 : 0) +
                  (hasChats && _hasMoreBefore ? 1 : 0);

              print('🏗️ itemCount: $itemCount');

              return ListView.separated(
                controller: _scrollController,
                reverse: true,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // 상단 로딩 인디케이터 (reverse에서는 하단)
                  if (hasChats && _hasMoreAfter && index == 0) {
                    print('🔄 이후 채팅 로딩 인디케이터 표시');
                    return _buildLoadingIndicator();
                  }

                  // 하단 로딩 인디케이터 (reverse에서는 상단)
                  final bottomLoadingIndex = chatList.length + (hasChats && _hasMoreAfter ? 1 : 0);
                  if (hasChats && _hasMoreBefore && index == bottomLoadingIndex) {
                    print('🔄 이전 채팅 로딩 인디케이터 표시 (index: $index)');
                    return _buildLoadingIndicator();
                  }

                  // 실제 채팅/로그 아이템
                  final actualIndex = index - (hasChats && _hasMoreAfter ? 1 : 0);
                  if (actualIndex < 0 || actualIndex >= chatList.length) {
                    return const SizedBox.shrink();
                  }

                  final item = chatList[actualIndex];

                  if (item is Chat) {
                    return _buildChatItem(item, actualIndex, chatList);
                  } else if (item is RoomLog) {
                    return _buildLogItem(item, actualIndex, chatList);
                  }

                  return const SizedBox.shrink();
                },
                separatorBuilder: (context, index) => SizedBox(height: 4.h),
              );
            },
          ),
        ),

        // 전송 중인 이미지 표시
        if (widget.roomProvider.sendingImage.isNotEmpty) ...[
          SizedBox(height: 8.h),
          SendingImagesPlaceHolder(images: widget.roomProvider.sendingImage),
        ],
      ],
    );
  }
}