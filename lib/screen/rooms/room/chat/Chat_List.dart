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
  final Map<String, GlobalKey> _itemKeys = {}; // 키 관리 개선

  bool _hasMoreBefore = false;
  bool _hasMoreAfter = false;
  bool _isInitialized = false;
  bool _isLoadingMore = false; // 로딩 상태 추가
  int? _lastReadChatId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _itemKeys.clear();
    super.dispose();
  }

  void _onScroll() {
    if (chatProvider.socketLoading || _isLoadingMore) return;

    final position = _scrollController.position;

    // 스크롤 위치 확인을 더 엄격하게
    if (position.pixels <= 100 && _hasMoreBefore && !_isLoadingMore) {
      _loadMoreBefore();
    }

    if (position.pixels >= position.maxScrollExtent - 100 && _hasMoreAfter && !_isLoadingMore) {
      _loadMoreAfter();
    }
  }

  Future<void> _loadMoreBefore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final roomId = widget.roomProvider.room!['roomId'];
      final hasMore = await chatProvider.loadChatsBefore(roomId);

      if (mounted) {
        setState(() {
          _hasMoreBefore = hasMore;
        });
      }
    } catch (e) {
      print('이전 채팅 로드 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreAfter() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final roomId = widget.roomProvider.room!['roomId'];
      final hasMore = await chatProvider.loadChatsAfter(roomId);

      if (mounted) {
        setState(() {
          _hasMoreAfter = hasMore;
        });
      }
    } catch (e) {
      print('이후 채팅 로드 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 키 생성 함수 개선
  GlobalKey _getItemKey(String identifier) {
    return _itemKeys.putIfAbsent(identifier, () => GlobalKey());
  }

  void _scrollToChatId(int chatId) {
    final key = _getItemKey('chat_$chatId');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null && mounted) {
        try {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        } catch (e) {
          print('스크롤 이동 오류: $e');
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final shouldShowMoreBefore = chats.length >= 20;

        setState(() {
          _hasMoreBefore = shouldShowMoreBefore;
        });

        // lastRead 위치로 스크롤
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

  // 안전한 데이터 조합 함수
  List<dynamic> _getCombinedChatList() {
    final roomId = widget.roomProvider.room!['roomId'];
    final chats = chatProvider.chat[roomId] ?? [];
    final logs = widget.roomProvider.roomLog;

    var combinedList = <dynamic>[
      ...chats,
      ...logs,
    ];

    try {
      combinedList.sort((a, b) {
        final aDate = a is Chat ? a.createAt : (a as RoomLog).createAt;
        final bDate = b is Chat ? b.createAt : (b as RoomLog).createAt;
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      print('정렬 오류: $e');
      return [];
    }

    return combinedList;
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context);

    _initializeIfNeeded();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Consumer2<ChatProvider, RoomProvider>(
            builder: (context, chatProv, roomProv, child) {
              final chatList = _getCombinedChatList();

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

              final totalCount = chatList.length +
                  (_hasMoreBefore ? 1 : 0) +
                  (_hasMoreAfter ? 1 : 0);

              return ListView.separated(
                key: const PageStorageKey('chat_list'),
                controller: _scrollController,
                reverse: true,
                itemCount: totalCount,
                cacheExtent: 200, // 캐시 범위 설정
                itemBuilder: (context, index) {
                  // 위쪽 로딩 인디케이터
                  if (_hasMoreBefore && index == chatList.length) {
                    return Container(
                      key: _getItemKey('loading_before'),
                      padding: const EdgeInsets.all(16),
                      child: Center(child: NadalCircular(size: 24.r)),
                    );
                  }

                  // 아래쪽 로딩 인디케이터
                  if (_hasMoreAfter && index == totalCount - 1) {
                    return Container(
                      key: _getItemKey('loading_after'),
                      padding: const EdgeInsets.all(16),
                      child: Center(child: NadalCircular(size: 24.r)),
                    );
                  }

                  final actualIndex = index - (_hasMoreAfter ? 1 : 0);

                  if (actualIndex < 0 || actualIndex >= chatList.length) {
                    return const SizedBox.shrink();
                  }

                  final currentData = chatList[actualIndex];

                  // 로그 데이터 처리
                  if (currentData is RoomLog) {
                    return Container(
                      key: _getItemKey('log_${currentData.logId}'),
                      child: LogFrame(roomLog: currentData),
                    );
                  }

                  // 채팅 데이터 처리
                  final chat = currentData as Chat;

                  // 안전한 이전/다음 데이터 참조
                  Chat? previousData;
                  Chat? nextData;

                  try {
                    if (actualIndex < chatList.length - 1) {
                      final prevItem = chatList[actualIndex + 1];
                      if (prevItem is Chat) previousData = prevItem;
                    }

                    if (actualIndex > 0) {
                      final nextItem = chatList[actualIndex - 1];
                      if (nextItem is Chat) nextData = nextItem;
                    }
                  } catch (e) {
                    print('이전/다음 데이터 참조 오류: $e');
                  }

                  // 날짜 출력 여부 결정
                  final cDate = DateTime(chat.createAt.year, chat.createAt.month, chat.createAt.day);
                  final pDate = previousData != null
                      ? DateTime(previousData.createAt.year, previousData.createAt.month, previousData.createAt.day)
                      : null;

                  final showDate = (actualIndex == chatList.length - 1) || (cDate != pDate);

                  // 시간, 꼬리 출력 여부 결정
                  bool timeVisible = nextData == null ||
                      nextData.uid != chat.uid ||
                      nextData.createAt.difference(chat.createAt).inMinutes > 5;

                  bool tail = previousData == null ||
                      previousData.uid != chat.uid ||
                      chat.createAt.difference(previousData.createAt).inMinutes > 5;

                  // 읽음 표시 계산 (안전하게)
                  int read = 0;
                  try {
                    final totalMembers = widget.roomProvider.roomMembers.keys.length;
                    final readMembers = widget.roomProvider.roomMembers.values
                        .where((e) => (e['lastRead'] ?? 0) >= chat.chatId)
                        .length;
                    read = totalMembers - readMembers;
                  } catch (e) {
                    print('읽음 수 계산 오류: $e');
                  }

                  // lastRead 구분선 표시 여부
                  final showLastReadDivider = _shouldShowLastReadDivider(chat, actualIndex, chatList);

                  return Container(
                    key: _getItemKey('chat_${chat.chatId}'),
                    child: Column(
                      children: [
                        // 날짜 구분선 표시
                        if (showDate)
                          DateDivider(
                            key: ValueKey('date_${cDate.toIso8601String()}'),
                            date: cDate,
                          ),

                        // lastRead 구분선 표시
                        if (showLastReadDivider)
                          Container(
                            key: ValueKey('lastread_${chat.chatId}'),
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

                        // 채팅 메시지 표시
                        ChatFrame(
                          key: ValueKey('frame_${chat.chatId}'),
                          chat: chat,
                          timeVisible: timeVisible,
                          tail: tail,
                          read: read,
                          index: actualIndex,
                          roomProvider: widget.roomProvider,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: 4.h),
              );
            },
          ),
        ),
        if (widget.roomProvider.sendingImage.isNotEmpty) ...[
          SizedBox(height: 8.h),
          SendingImagesPlaceHolder(images: widget.roomProvider.sendingImage)
        ]
      ],
    );
  }
}