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
  final Map<int, GlobalKey> _chatKeys = {};

  bool _hasMoreBefore = true;
  bool _hasMoreAfter = true;
  bool _isInitialized = false;
  int? _lastReadChatId;

  Timer? _scrollDebouncer;
  bool _isLoadingBefore = false;
  bool _isLoadingAfter = false;

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

  void _onScroll() {
    if (chatProvider.socketLoading || _isLoadingBefore || _isLoadingAfter) {
      print('스크롤 무시: socketLoading=${chatProvider.socketLoading}, loadingBefore=$_isLoadingBefore, loadingAfter=$_isLoadingAfter');
      return;
    }

    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final position = _scrollController.position;
      print('스크롤 위치: pixels=${position.pixels.toStringAsFixed(2)}, maxScrollExtent=${position.maxScrollExtent.toStringAsFixed(2)}');
      print('hasMoreBefore=$_hasMoreBefore, hasMoreAfter=$_hasMoreAfter');

      // reverse ListView에서는 조건이 반대
      // 위로 스크롤 (이전 채팅) - maxScrollExtent 근처
      if (position.pixels >= position.maxScrollExtent - 200.h && _hasMoreBefore && !_isLoadingBefore) {
        print('✅ 이전 채팅 로드 트리거: pixels=${position.pixels}, threshold=${position.maxScrollExtent - 200.h}');
        _loadMoreBefore();
      }

      // 아래로 스크롤 (이후 채팅) - 0 근처
      if (position.pixels <= 200.h && _hasMoreAfter && !_isLoadingAfter) {
        print('✅ 이후 채팅 로드 트리거: pixels=${position.pixels}');
        _loadMoreAfter();
      }
    });
  }

  Future<void> _loadMoreBefore() async {
    if (_isLoadingBefore || chatProvider.socketLoading) {
      print('❌ _loadMoreBefore 중단: 이미 로딩 중');
      return;
    }

    try {
      _isLoadingBefore = true;
      print('🔄 _loadMoreBefore 시작');

      final roomId = widget.roomProvider.room?['roomId'] as int?;
      if (roomId == null) {
        print('❌ roomId is null');
        return;
      }

      final currentChats = chatProvider.chat[roomId] ?? [];
      print('현재 채팅 수: ${currentChats.length}');

      if (currentChats.isNotEmpty) {
        // 서버 로직에 맞게 chatId 기준으로 가장 오래된 채팅 찾기
        final sortedByIdChats = [...currentChats]..sort((a, b) => a.chatId.compareTo(b.chatId));
        print('가장 오래된 채팅: ID=${sortedByIdChats.first.chatId}, createAt=${sortedByIdChats.first.createAt}');
      }

      final hasMore = await chatProvider.loadChatsBefore(roomId);
      print('✅ _loadMoreBefore 결과: hasMore=$hasMore');

      final newChats = chatProvider.chat[roomId] ?? [];
      print('로드 후 채팅 수: ${newChats.length}');

      if (mounted) {
        _hasMoreBefore = hasMore;
        print('_hasMoreBefore 업데이트: $_hasMoreBefore');
        if (mounted) notifyListeners();
      }
    } catch (e) {
      print('❌ 이전 채팅 로드 오류: $e');
    } finally {
      _isLoadingBefore = false;
      print('🔄 _loadMoreBefore 완료');
    }
  }

  Future<void> _loadMoreAfter() async {
    if (_isLoadingAfter || chatProvider.socketLoading) {
      print('❌ _loadMoreAfter 중단: 이미 로딩 중');
      return;
    }

    try {
      _isLoadingAfter = true;
      print('🔄 _loadMoreAfter 시작');

      final roomId = widget.roomProvider.room?['roomId'] as int?;
      if (roomId == null) {
        print('❌ roomId is null');
        return;
      }

      final hasMore = await chatProvider.loadChatsAfter(roomId);
      print('✅ _loadMoreAfter 결과: hasMore=$hasMore');

      if (mounted) {
        _hasMoreAfter = hasMore;
        print('_hasMoreAfter 업데이트: $_hasMoreAfter');
        if (mounted) notifyListeners();
      }
    } catch (e) {
      print('❌ 이후 채팅 로드 오류: $e');
    } finally {
      _isLoadingAfter = false;
      print('🔄 _loadMoreAfter 완료');
    }
  }

  GlobalKey? _getChatKey(int chatId) {
    if (_chatKeys.containsKey(chatId)) {
      final existingKey = _chatKeys[chatId]!;
      if (existingKey.currentContext == null) {
        return existingKey;
      } else {
        return null;
      }
    }

    final newKey = GlobalKey();
    _chatKeys[chatId] = newKey;
    return newKey;
  }

  void _scrollToChatId(int chatId) {
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
          print('스크롤 실패: $e');
        }
      }
    });
  }

  void _initializeIfNeeded() {
    if (_isInitialized) return;

    try {
      final roomId = widget.roomProvider.room?['roomId'] as int?;
      if (roomId == null) return;

      final chats = chatProvider.chat[roomId];
      if (chats == null || chats.isEmpty) {
        print('🔍 초기화 대기: 채팅 없음');
        return;
      }

      _isInitialized = true;
      _lastReadChatId = chatProvider.getLastReadChatId(roomId);

      print('🚀 채팅 리스트 초기화');
      print('- 총 채팅 수: ${chats.length}');
      print('- lastReadChatId: $_lastReadChatId');

      if (chats.isNotEmpty) {
        // 서버는 chatId 기준으로 정렬하므로 chatId 기준으로 분석
        final sortedByIdChats = [...chats]..sort((a, b) => a.chatId.compareTo(b.chatId));
        print('- chatId 기준 가장 오래된 채팅: ID=${sortedByIdChats.first.chatId}, createAt=${sortedByIdChats.first.createAt}');
        print('- chatId 기준 가장 최신 채팅: ID=${sortedByIdChats.last.chatId}, createAt=${sortedByIdChats.last.createAt}');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // hasMoreBefore: 더 오래된 채팅(chatId가 더 작은)이 있는가?
        // 서버 로직: getChatsBefore에서 c.chatId < lastChatId 조건으로 20개씩 가져옴
        // 초기 로딩에서 읽은 채팅 10개만 가져오므로, 채팅 수가 적으면 더 있을 가능성
        _hasMoreBefore = chats.length < 60; // 서버에서 최대 60개(안읽은50+읽은10) 가져오는데 그보다 적으면 더 있음

        // hasMoreAfter: 더 최신 채팅(chatId가 더 큰)이 있는가?
        // 서버 로직: getChatsAfter에서 c.chatId > lastChatId 조건으로 20개씩 가져옴
        // 초기 로딩에서 안읽은 채팅을 최대 50개 가져오는데, 그보다 적으면 더 없을 가능성
        if (_lastReadChatId != null && chats.isNotEmpty) {
          final sortedByIdChats = [...chats]..sort((a, b) => a.chatId.compareTo(b.chatId));
          final oldestChatId = sortedByIdChats.first.chatId;
          final newestChatId = sortedByIdChats.last.chatId;
          final unreadChatsInList = chats.where((c) => c.chatId > _lastReadChatId!).length;

          // 안읽은 채팅이 50개 미만이면 더 최신 채팅이 없을 가능성 높음
          _hasMoreAfter = unreadChatsInList >= 50;

          print('🔍 hasMoreAfter 판단:');
          print('- oldestChatId: $oldestChatId');
          print('- newestChatId: $newestChatId');
          print('- lastReadChatId: $_lastReadChatId');
          print('- unreadChatsInList: $unreadChatsInList');
          print('- hasMoreAfter: $_hasMoreAfter');
        } else {
          _hasMoreAfter = false;
        }

        print('_hasMoreBefore 초기값: $_hasMoreBefore (채팅 수: ${chats.length})');
        print('_hasMoreAfter 초기값: $_hasMoreAfter');

        if (mounted) notifyListeners();

        if (_lastReadChatId != null && _lastReadChatId! > 0) {
          final targetExists = chats.any((chat) => chat.chatId == _lastReadChatId);
          print('lastRead 스크롤 타겟 존재: $targetExists');
          if (targetExists) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _scrollToChatId(_lastReadChatId!);
              }
            });
          }
        }
      });
    } catch (e) {
      print('❌ 초기화 오류: $e');
    }
  }

  bool _shouldShowLastReadDivider(Chat chat, int actualIndex, List<dynamic> chatList) {
    if (_lastReadChatId == null || _lastReadChatId! <= 0) return false;
    if (chat.chatId != _lastReadChatId) return false;
    if (actualIndex >= chatList.length - 1) return false;

    try {
      final roomId = widget.roomProvider.room?['roomId'] as int?;
      if (roomId == null) return false;

      final chats = chatProvider.chat[roomId] ?? [];
      if (chats.isEmpty) return false;

      final unreadCount = chats.where((c) => c.chatId > _lastReadChatId!).length;
      return unreadCount > 10;
    } catch (e) {
      print('읽음 구분선 표시 확인 오류: $e');
      return false;
    }
  }

  void _cleanupUnusedKeys(List<dynamic> currentChatList) {
    try {
      final currentChatIds = currentChatList
          .whereType<Chat>()
          .map((chat) => chat.chatId)
          .toSet();

      _chatKeys.removeWhere((chatId, key) =>
      !currentChatIds.contains(chatId) && key.currentContext == null);
    } catch (e) {
      print('키 정리 오류: $e');
    }
  }

  void notifyListeners() {
    if (mounted) {
      setState(() {});
    }
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
              try {
                final roomId = roomProvider.room?['roomId'] as int?;
                if (roomId == null) return <dynamic>[];

                final chats = chatProvider.chat[roomId] ?? [];

                // 채팅이 없으면 빈 리스트 반환
                if (chats.isEmpty) return <dynamic>[];

                // 현재 로드된 채팅들의 날짜 범위 계산
                final chatDates = chats.map((chat) => chat.createAt).toList();
                final oldestChatDate = chatDates.reduce((a, b) => a.isBefore(b) ? a : b);
                final newestChatDate = chatDates.reduce((a, b) => a.isAfter(b) ? a : b);

                // 해당 날짜 범위에 속하는 로그만 필터링
                final filteredLogs = roomProvider.roomLog.where((log) {
                  return log.createAt.isAfter(oldestChatDate.subtract(const Duration(hours: 1))) &&
                      log.createAt.isBefore(newestChatDate.add(const Duration(hours: 1)));
                }).toList();

                var combinedList = <dynamic>[
                  ...chats,
                  ...filteredLogs
                ];

                combinedList.sort((a, b) {
                  try {
                    final aDate = a.runtimeType == Chat
                        ? (a as Chat).createAt
                        : (a as RoomLog).createAt;
                    final bDate = b.runtimeType == Chat
                        ? (b as Chat).createAt
                        : (b as RoomLog).createAt;
                    return bDate.compareTo(aDate);
                  } catch (e) {
                    print('정렬 오류: $e');
                    return 0;
                  }
                });

                return combinedList;
              } catch (e) {
                print('채팅 목록 선택 오류: $e');
                return <dynamic>[];
              }
            },
            builder: (context, chatList, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cleanupUnusedKeys(chatList);
              });

              if (chatList.isEmpty) {
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

              print('📋 채팅 리스트 렌더링: ${chatList.length}개 아이템 (hasMoreBefore: $_hasMoreBefore, hasMoreAfter: $_hasMoreAfter)');

              return ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                reverse: true,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: chatList.length + (_hasMoreBefore ? 1 : 0) + (_hasMoreAfter ? 1 : 0),
                itemBuilder: (context, index) {
                  try {
                    // 위쪽 로딩 인디케이터 (reverse에서는 실제로는 아래쪽)
                    if (_hasMoreAfter && index == 0) {
                      print('🔄 이후 채팅 로딩 인디케이터 표시');
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(child: NadalCircular(size: 30.r)),
                      );
                    }

                    // 아래쪽 로딩 인디케이터 (reverse에서는 실제로는 위쪽)
                    if (_hasMoreBefore && index == chatList.length + (_hasMoreAfter ? 1 : 0)) {
                      print('🔄 이전 채팅 로딩 인디케이터 표시 (index: $index)');
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(child: NadalCircular(size: 30.r)),
                      );
                    }

                    final actualIndex = index - (_hasMoreAfter ? 1 : 0);
                    if (actualIndex < 0 || actualIndex >= chatList.length) {
                      return SizedBox.shrink();
                    }

                    final currentData = chatList[actualIndex];

                    // 로그 데이터 처리
                    if (currentData is RoomLog) {
                      return _buildLogItem(currentData, actualIndex, chatList);
                    }

                    // 채팅 데이터 처리
                    final chat = currentData as Chat;
                    return _buildChatItem(chat, actualIndex, chatList);

                  } catch (e) {
                    print('아이템 빌드 오류 (index: $index): $e');
                    return SizedBox.shrink();
                  }
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

  Widget _buildLogItem(RoomLog roomLog, int actualIndex, List<dynamic> chatList) {
    try {
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
    } catch (e) {
      print('로그 아이템 빌드 오류: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildChatItem(Chat chat, int actualIndex, List<dynamic> chatList) {
    try {
      // 이전 및 다음 데이터 참조 (안전하게)
      Chat? previousData;
      Chat? nextData;

      if (actualIndex < chatList.length - 1 && chatList[actualIndex + 1] is Chat) {
        previousData = chatList[actualIndex + 1] as Chat;
      }

      if (actualIndex > 0 && chatList[actualIndex - 1] is Chat) {
        nextData = chatList[actualIndex - 1] as Chat;
      }

      // 날짜 출력 여부 결정
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

      // 읽음 표시 계산 (안전하게)
      int read = 0;
      try {
        final roomMembers = widget.roomProvider.roomMembers;
        if (roomMembers.isNotEmpty) {
          final totalMembers = roomMembers.keys.length;
          final readMembers = roomMembers.values
              .where((e) => (e['lastRead'] as int? ?? 0) > chat.chatId)
              .length;
          read = totalMembers - readMembers;
        }
      } catch (e) {
        print('읽음 표시 계산 오류: $e');
      }

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
            ),

          // 채팅 메시지 표시
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
    } catch (e) {
      print('채팅 아이템 빌드 오류: $e');
      return SizedBox.shrink();
    }
  }
}