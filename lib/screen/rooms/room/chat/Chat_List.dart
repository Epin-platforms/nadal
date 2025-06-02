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
  late ChatProvider chatProvider;
  final ScrollController _scrollController = ScrollController();

  // GlobalKey 관리를 위한 맵 - 메모리 누수 방지를 위해 WeakReference 패턴 적용
  final Map<int, GlobalKey> _chatKeys = {};

  bool _hasMoreBefore = true;
  bool _hasMoreAfter = true;
  bool _isInitialized = false;
  int? _lastReadChatId;

  // 스크롤 성능 최적화를 위한 디바운스
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
    // GlobalKey 맵 정리
    _chatKeys.clear();
    super.dispose();
  }

  void _onScroll() {
    if (chatProvider.socketLoading) return;

    // 디바운스로 스크롤 성능 최적화
    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final position = _scrollController.position;

      if (position.pixels <= 50 && _hasMoreBefore) {
        _loadMoreBefore();
      }

      if (position.pixels >= position.maxScrollExtent - 50 && _hasMoreAfter) {
        _loadMoreAfter();
      }
    });
  }

  Future<void> _loadMoreBefore() async {
    if (chatProvider.socketLoading) return;

    final roomId = widget.roomProvider.room!['roomId'];
    final hasMore = await chatProvider.loadChatsBefore(roomId);

    if (mounted && _hasMoreBefore != hasMore) {
      setState(() {
        _hasMoreBefore = hasMore;
      });
    }
  }

  Future<void> _loadMoreAfter() async {
    if (chatProvider.socketLoading) return;

    final roomId = widget.roomProvider.room!['roomId'];
    final hasMore = await chatProvider.loadChatsAfter(roomId);
    if (mounted && _hasMoreAfter != hasMore) {
      setState(() {
        _hasMoreAfter = hasMore;
      });
    }
  }

  // GlobalKey 중복 방지를 위한 안전한 키 생성
  GlobalKey? _getChatKey(int chatId) {
    // 이미 존재하는 키가 있고, 해당 키가 현재 위젯 트리에서 사용 중이 아닌 경우에만 재사용
    if (_chatKeys.containsKey(chatId)) {
      final existingKey = _chatKeys[chatId]!;
      // 키가 현재 사용되고 있지 않은 경우에만 재사용
      if (existingKey.currentContext == null) {
        return existingKey;
      } else {
        // 이미 사용 중인 키가 있다면 null 반환 (ValueKey 사용)
        return null;
      }
    }

    // 새로운 키 생성
    final newKey = GlobalKey();
    _chatKeys[chatId] = newKey;
    return newKey;
  }

  void _scrollToChatId(int chatId) {
    // 안전한 스크롤링을 위한 지연 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final key = _chatKeys[chatId];
      if (key?.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.5,
          );
        } catch (e) {
          // 스크롤 실패 시 무시
          debugPrint('스크롤 실패: $e');
        }
      }
    });
  }

  void _initializeIfNeeded() {
    if (_isInitialized) return;

    final roomId = widget.roomProvider.room!['roomId'];
    final chats = chatProvider.chat[roomId];

    if (chats == null || chats.isEmpty) return;

    _isInitialized = true;
    _lastReadChatId = chatProvider.getLastReadChatId(roomId);

    final shouldShowMoreBefore = chats.length >= 20;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _hasMoreBefore = shouldShowMoreBefore;
      });

      // lastRead 위치로 스크롤 (안전하게)
      if (_lastReadChatId != null && _lastReadChatId! > 0) {
        final targetExists = chats.any((chat) => chat.chatId == _lastReadChatId);
        if (targetExists) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _scrollToChatId(_lastReadChatId!);
            }
          });
        }
      }
    });
  }

  bool _shouldShowLastReadDivider(Chat chat, int actualIndex, List<dynamic> chatList) {
    if (_lastReadChatId == null || _lastReadChatId! <= 0) return false;
    if (chat.chatId != _lastReadChatId) return false;
    if (actualIndex >= chatList.length - 1) return false;

    final roomId = widget.roomProvider.room!['roomId'];
    final chats = chatProvider.chat[roomId] ?? [];

    if (chats.isEmpty) return false;

    final unreadCount = chats.where((c) => c.chatId > _lastReadChatId!).length;
    return unreadCount > 10;
  }

  // 메모리 효율성을 위한 키 정리
  void _cleanupUnusedKeys(List<dynamic> currentChatList) {
    final currentChatIds = currentChatList
        .whereType<Chat>()
        .map((chat) => chat.chatId)
        .toSet();

    _chatKeys.removeWhere((chatId, key) =>
    !currentChatIds.contains(chatId) && key.currentContext == null);
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context);
    _initializeIfNeeded();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Selector2<ChatProvider, RoomProvider, List<dynamic>>(
            selector: (context, chatProvider, roomProvider) {
              final roomId = roomProvider.room!['roomId'];
              var combinedList = [
                ...chatProvider.chat[roomId] ?? [],
                ...roomProvider.roomLog
              ];

              combinedList.sort((a, b) {
                final aDate = a.runtimeType == Chat ? (a as Chat).createAt : (a as RoomLog).createAt;
                final bDate = b.runtimeType == Chat ? (b as Chat).createAt : (b as RoomLog).createAt;
                return bDate.compareTo(aDate);
              });

              return combinedList;
            },
            builder: (context, chatList, child) {
              // 사용되지 않는 키 정리
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cleanupUnusedKeys(chatList);
              });

              if (chatList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      '아직 채팅이 없어요\n첫 메시지를 보내보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                reverse: true,
                // 성능 최적화를 위한 캐싱
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: chatList.length + (_hasMoreBefore ? 1 : 0) + (_hasMoreAfter ? 1 : 0),
                itemBuilder: (context, index) {
                  // 위쪽 로딩 인디케이터
                  if (_hasMoreBefore && index == chatList.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(child: NadalCircular(size: 30.r)),
                    );
                  }

                  // 아래쪽 로딩 인디케이터
                  if (_hasMoreAfter && index == chatList.length + (_hasMoreBefore ? 1 : 0)) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(child: NadalCircular(size: 30.r)),
                    );
                  }

                  final actualIndex = index - (_hasMoreAfter ? 1 : 0);
                  final currentData = chatList[actualIndex];

                  // 로그 데이터 처리
                  if (currentData is RoomLog) {
                    final roomLog = currentData;

                    // 날짜 출력 여부 결정 (전체 리스트 기준)
                    final cDate = DateTime(roomLog.createAt.year, roomLog.createAt.month, roomLog.createAt.day);

                    DateTime? pDate;
                    if (actualIndex < chatList.length - 1) {
                      final prevItem = chatList[actualIndex + 1];
                      final prevItemDate = prevItem.runtimeType == Chat
                          ? (prevItem as Chat).createAt
                          : (prevItem as RoomLog).createAt;
                      pDate = DateTime(prevItemDate.year, prevItemDate.month, prevItemDate.day);
                    }

                    final showDate = (actualIndex == chatList.length - 1) || (cDate != pDate);

                    return Column(
                      children: [
                        // 날짜 구분선 표시
                        if (showDate)
                          DateDivider(
                            key: ValueKey('date-${cDate.toIso8601String()}'),
                            date: cDate,
                          ),

                        LogFrame(
                          key: ValueKey('log-${roomLog.logId}'),
                          roomLog: roomLog,
                        ),
                      ],
                    );
                  }

                  // 채팅 데이터 처리
                  final chat = currentData as Chat;

                  // 이전 및 다음 데이터 참조
                  final previousData = (actualIndex < chatList.length - 1 && chatList[actualIndex + 1] is Chat)
                      ? chatList[actualIndex + 1] as Chat
                      : null;

                  final nextData = (actualIndex > 0 && chatList[actualIndex - 1] is Chat)
                      ? chatList[actualIndex - 1] as Chat
                      : null;

                  // 날짜 출력 여부 결정 (전체 리스트 기준)
                  final cDate = DateTime(chat.createAt.year, chat.createAt.month, chat.createAt.day);

                  DateTime? pDate;
                  if (actualIndex < chatList.length - 1) {
                    final prevItem = chatList[actualIndex + 1];
                    final prevItemDate = prevItem.runtimeType == Chat
                        ? (prevItem as Chat).createAt
                        : (prevItem as RoomLog).createAt;
                    pDate = DateTime(prevItemDate.year, prevItemDate.month, prevItemDate.day);
                  }

                  final showDate = (actualIndex == chatList.length - 1) || (cDate != pDate);

                  // 시간, 꼬리 출력 여부 결정
                  bool timeVisible = nextData == null ||
                      nextData.uid != chat.uid ||
                      nextData.createAt.difference(chat.createAt).inMinutes > 5;

                  bool tail = previousData == null ||
                      previousData.uid != chat.uid ||
                      chat.createAt.difference(previousData.createAt).inMinutes > 5;

                  // 읽음 표시 계산
                  int read = (widget.roomProvider.roomMembers.keys.length -
                      widget.roomProvider.roomMembers.values.where((e) => e['lastRead'] > chat.chatId).length);

                  // lastRead 구분선 표시 여부
                  final showLastReadDivider = _shouldShowLastReadDivider(chat, actualIndex, chatList);

                  // GlobalKey 또는 ValueKey 결정
                  final chatKey = _getChatKey(chat.chatId);
                  final useGlobalKey = chatKey != null && chat.chatId == _lastReadChatId;

                  return Column(
                    children: [
                      // 날짜 구분선 표시
                      if (showDate)
                        DateDivider(
                          key: ValueKey('date-${cDate.toIso8601String()}'),
                          date: cDate,
                        ),

                      // lastRead 구분선 표시
                      if (showLastReadDivider)
                        Container(
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
                                    fontSize: 11,
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
                        ),

                      // 채팅 메시지 표시 - GlobalKey 중복 방지
                      Container(
                        key: useGlobalKey ? chatKey : ValueKey('chat-${chat.chatId}'),
                        child: ChatFrame(
                          key: ValueKey('frame-${chat.chatId}'),
                          chat: chat,
                          timeVisible: timeVisible,
                          tail: tail,
                          read: read,
                          index: actualIndex,
                          roomProvider: widget.roomProvider,
                        ),
                      ),
                    ],
                  );
                },
                separatorBuilder: (BuildContext context, int index) => SizedBox(height: 4.h),
              );
            },
          ),
        ),
        if(widget.roomProvider.sendingImage.isNotEmpty)...[
          SizedBox(height: 8.h),
          SendingImagesPlaceHolder(images: widget.roomProvider.sendingImage)
        ]
      ],
    );
  }
}