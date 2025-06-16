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

  bool _hasMoreBefore = true;
  bool _hasMoreAfter = false;
  bool _isLoadingBefore = false;
  bool _isLoadingAfter = false;

  Timer? _scrollDebouncer;
  Timer? _initTimer;

  // 🔧 초기화 상태 관리 (setState 최소화)
  bool _isInitialized = false;
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForInitialization();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebouncer?.cancel();
    _initTimer?.cancel();
    super.dispose();
  }

  // 🔧 초기화 대기 (디바운싱 적용)
  void _waitForInitialization() {
    if (!mounted) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    final chatProvider = context.read<ChatProvider>();

    // 데이터 준비 상태 확인
    final isReady = _isDataReady(chatProvider, roomId);

    if (isReady && !_isInitialized) {
      _initializeScrollPosition();
      _isInitialized = true;
      _dataReady = true;

      // 한 번만 setState 호출
      if (mounted) {
        setState(() {});
      }
      return;
    }

    // 아직 준비되지 않았으면 재시도 (디바운싱)
    _initTimer?.cancel();
    _initTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _waitForInitialization();
      }
    });
  }

  // 🔧 데이터 준비 상태 확인 (예외 처리 강화)
  bool _isDataReady(ChatProvider chatProvider, int roomId) {
    try {
      final chats = chatProvider.chat[roomId];
      final myData = chatProvider.my[roomId];
      final isJoined = chatProvider.isJoined(roomId);

      return chats != null && myData != null && isJoined && !chatProvider.socketLoading;
    } catch (e) {
      print('❌ 데이터 준비 상태 확인 오류: $e');
      return false;
    }
  }

  void _initializeScrollPosition() {
    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    final chatProvider = context.read<ChatProvider>();
    final chats = chatProvider.chat[roomId] ?? [];
    final myData = chatProvider.my[roomId];

    if (chats.isEmpty) {
      _hasMoreBefore = false;
      _hasMoreAfter = false;
      print('📊 초기 설정: 채팅이 없음');
      return;
    }

    _hasMoreBefore = chats.length >= 15;

    final lastRead = myData?['lastRead'] as int? ?? 0;
    final unreadCount = chats.where((c) => c.chatId > lastRead).length;
    _hasMoreAfter = unreadCount >= 30 || chats.length >= 50;

    print('📊 초기 설정: before=$_hasMoreBefore, after=$_hasMoreAfter');
    print('📊 채팅수=${chats.length}, 안읽은수=$unreadCount, lastRead=$lastRead');
  }

  void _onScroll() {
    if (!mounted || !_isInitialized) return;
    if (_isLoadingBefore || _isLoadingAfter) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent < 300.h) return;

    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted || !_isInitialized) return;
      if (_isLoadingBefore || _isLoadingAfter) return;

      final pixels = position.pixels;
      final maxScrollExtent = position.maxScrollExtent;

      const double threshold = 400.0;

      // reverse ListView: 위로 스크롤 = 이전 채팅 로드
      if (pixels >= maxScrollExtent - threshold && _hasMoreBefore && !_isLoadingBefore) {
        _loadMoreBefore();
      }

      // reverse ListView: 아래로 스크롤 = 이후 채팅 로드
      if (pixels <= threshold && _hasMoreAfter && !_isLoadingAfter) {
        _loadMoreAfter();
      }
    });
  }

  Future<void> _loadMoreBefore() async {
    if (_isLoadingBefore || !_hasMoreBefore || !_isInitialized) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    print('📥 이전 채팅 로드 시작');

    // 로딩 상태 설정 (setState 한 번만)
    _isLoadingBefore = true;
    if (mounted) setState(() {});

    try {
      final chatProvider = context.read<ChatProvider>();
      final hasMore = await chatProvider.loadChatsBefore(roomId);

      print('📥 이전 채팅 로드 완료: hasMore=$hasMore');

      // 결과 업데이트 (setState 한 번만)
      _hasMoreBefore = hasMore;
      _isLoadingBefore = false;
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ 이전 채팅 로드 오류: $e');
      _hasMoreBefore = false;
      _isLoadingBefore = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadMoreAfter() async {
    if (_isLoadingAfter || !_hasMoreAfter || !_isInitialized) return;

    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return;

    print('📤 이후 채팅 로드 시작');

    // 로딩 상태 설정 (setState 한 번만)
    _isLoadingAfter = true;
    if (mounted) setState(() {});

    try {
      final chatProvider = context.read<ChatProvider>();
      final hasMore = await chatProvider.loadChatsAfter(roomId);

      print('📤 이후 채팅 로드 완료: hasMore=$hasMore');

      // 결과 업데이트 (setState 한 번만)
      _hasMoreAfter = hasMore;
      _isLoadingAfter = false;
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ 이후 채팅 로드 오류: $e');
      _hasMoreAfter = false;
      _isLoadingAfter = false;
      if (mounted) setState(() {});
    }
  }

  // 🔧 통합 리스트 생성 (태그 정렬 문제 해결)
  List<dynamic> _buildCombinedList() {
    final roomId = widget.roomProvider.room?['roomId'] as int?;
    if (roomId == null) return [];

    final chatProvider = context.read<ChatProvider>();
    final chats = chatProvider.chat[roomId] ?? [];
    final roomLogs = widget.roomProvider.roomLog;

    // 빈 상태 처리
    if (chats.isEmpty && roomLogs.isEmpty) return [];

    // 🔧 채팅이 없을 때 태그만 있는 경우 - 정렬 적용
    if (chats.isEmpty) {
      final sortedLogs = List<RoomLog>.from(roomLogs);
      // 최신 순으로 정렬 (reverse ListView에 맞춤)
      sortedLogs.sort((a, b) => b.createAt.compareTo(a.createAt));
      return sortedLogs.cast<dynamic>();
    }

    final chatDates = chats.map((chat) => chat.createAt).toList();
    if (chatDates.isEmpty) return chats.cast<dynamic>();

    final oldestDate = chatDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestDate = chatDates.reduce((a, b) => a.isAfter(b) ? a : b);

    // 관련 로그만 필터링
    final filteredLogs = roomLogs.where((log) {
      return log.createAt.isAfter(oldestDate.subtract(const Duration(hours: 1))) &&
          log.createAt.isBefore(newestDate.add(const Duration(hours: 1)));
    }).toList();

    final combinedList = <dynamic>[...chats, ...filteredLogs];

    // 일관된 정렬 (최신 순)
    combinedList.sort((a, b) {
      final aDate = a is Chat ? a.createAt : (a as RoomLog).createAt;
      final bDate = b is Chat ? b.createAt : (b as RoomLog).createAt;
      return bDate.compareTo(aDate);
    });

    return combinedList;
  }

  bool _shouldShowDateDivider(dynamic item, int index, List<dynamic> list) {
    if (index == list.length - 1) return true;

    final currentDate = item is Chat ? item.createAt : (item as RoomLog).createAt;
    final currentDay = DateTime(currentDate.year, currentDate.month, currentDate.day);

    final nextItem = list[index + 1];
    final nextDate = nextItem is Chat ? nextItem.createAt : (nextItem as RoomLog).createAt;
    final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);

    return currentDay != nextDay;
  }

  Widget _buildChatItem(Chat chat, int index, List<dynamic> list) {
    Chat? previousChat;
    Chat? nextChat;

    if (index < list.length - 1 && list[index + 1] is Chat) {
      previousChat = list[index + 1] as Chat;
    }
    if (index > 0 && list[index - 1] is Chat) {
      nextChat = list[index - 1] as Chat;
    }

    final timeVisible = nextChat == null ||
        nextChat.uid != chat.uid ||
        nextChat.createAt.difference(chat.createAt).inMinutes > 5;

    final tail = previousChat == null ||
        previousChat.uid != chat.uid ||
        chat.createAt.difference(previousChat.createAt).inMinutes > 5;

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

  Widget _buildLogItem(RoomLog roomLog, int index, List<dynamic> list) {
    return Column(
      children: [
        if (_shouldShowDateDivider(roomLog, index, list))
          DateDivider(date: roomLog.createAt),

        LogFrame(roomLog: roomLog),
      ],
    );
  }

  // 🔧 로딩 인디케이터 (애니메이션 최소화)
  Widget _buildLoadingIndicator(String type) {
    return Container(
      height: 60.h,
      width: double.infinity,
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                type == 'before' ? '이전 채팅 로드 중...' : '최신 채팅 로드 중...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 초기 로딩 상태 위젯 (애니메이션 최소화)
  Widget _buildInitialLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '채팅을 불러오는 중...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
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
              // 🔧 초기화되지 않은 상태 처리 (setState 최소화)
              if (!_isInitialized) {
                final roomId = widget.roomProvider.room?['roomId'] as int?;
                if (roomId != null && _isDataReady(chatProvider, roomId) && !_dataReady) {
                  // 데이터가 준비되었으면 초기화 수행
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeScrollPosition();
                    if (mounted) {
                      _isInitialized = true;
                      _dataReady = true;
                      setState(() {});
                    }
                  });
                }
                return _buildInitialLoadingState();
              }

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

              print('📊 리스트 렌더링: 아이템=${combinedList.length}, 로딩Before=$_isLoadingBefore, 로딩After=$_isLoadingAfter');

              return Column(
                children: [
                  // 🔧 상단 로딩 인디케이터 (이후 채팅 로드용)
                  if (_isLoadingAfter) _buildLoadingIndicator('after'),

                  // 메인 채팅 리스트 (ListView.builder로 최적화)
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: combinedList.length,
                      itemBuilder: (context, index) {
                        final item = combinedList[index];

                        if (item is Chat) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: _buildChatItem(item, index, combinedList),
                          );
                        } else if (item is RoomLog) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: _buildLogItem(item, index, combinedList),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // 🔧 하단 로딩 인디케이터 (이전 채팅 로드용)
                  if (_isLoadingBefore) _buildLoadingIndicator('before'),
                ],
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