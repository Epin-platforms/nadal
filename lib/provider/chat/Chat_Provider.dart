import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

class ChatProvider extends ChangeNotifier{
  final SocketManager socket = SocketManager();

  final Set<int> _joinedRooms = {};
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};
  final Map<int, int?> _lastReadChatId = {};
  final Map<int, Set<int>> _loadedChatIds = {};

  Map<int, List<Chat>> get chat => _chat;
  Map<int, Map<String, dynamic>> get my => _my;

  void myMemberUpdate({required int roomId, required String field, required dynamic data}){
    if (_my.containsKey(roomId) && _my[roomId] != null) {
      _my[roomId]![field] = data;

      // unreadCount 변경 시 즉시 배지 업데이트
      if (field == 'unreadCount') {
        _updateBadgeImmediately();
      }

      notifyListeners();
    }
  }

  Future<void> initializeSocket() async{
    await socket.connect();
    await initChatProvider(); // 소켓 연결 후 바로 채팅 데이터 로드
  }

  bool _socketLoading = false;
  bool get socketLoading => _socketLoading;

  void onDisconnect(){
    _joinedRooms.clear();
    notifyListeners();
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future initChatProvider() async{
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final roomsProvider = AppRoute.context?.read<RoomsProvider>();
      if (roomsProvider == null) return;

      // 두 타입의 방을 모두 처리
      final allRoomIds = <int>[
        ...?roomsProvider.rooms?.keys,
        ...?roomsProvider.quickRooms?.keys,
      ];

      print('📊 초기화할 방 목록: $allRoomIds');

      // 병렬 처리로 성능 개선하되 안전하게
      final futures = allRoomIds.map((roomId) async {
        try {
          if (!_joinedRooms.contains(roomId)) {
            await joinRoom(roomId);
            print('✅ 방 조인 성공: $roomId');
          }
        } catch (e) {
          print('❌ 방 조인 실패 (roomId: $roomId): $e');
        }
      });

      await Future.wait(futures);
      print('✅ 모든 방 초기화 완료');

    } catch (e) {
      print('❌ initChatProvider 오류: $e');
    } finally {
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> joinRoom(int roomId) async{
    if (_joinedRooms.contains(roomId)) return;

    try {
      await setChats(roomId);
      await setMyRoom(roomId);
      socket.emit('join', roomId);
      _joinedRooms.add(roomId);
      notifyListeners();
    } catch (e) {
      print('방 조인 오류 (roomId: $roomId): $e');
    }
  }

  void leaveRoom(int roomId) {
    if (_joinedRooms.remove(roomId)) {
      socket.emit('leave', {'roomId': roomId});
      notifyListeners();
    }
  }

  bool isJoined(int roomId) => _joinedRooms.contains(roomId);

  Set<int> get joinedRooms => _joinedRooms;

  List<Chat> getMessages(int roomId) => _chat[roomId] ?? [];

  Chat? latestChatTime(int roomId) {
    final chats = _chat[roomId];
    if (chats == null || chats.isEmpty) return null;

    try {
      return chats.reduce((a, b) => a.createAt.isAfter(b.createAt) ? a : b);
    } catch (e) {
      print('최신 채팅 시간 가져오기 오류: $e');
      return null;
    }
  }

  int? getLastReadChatId(int roomId) => _lastReadChatId[roomId];

  void setSocketListeners(){
    socket.on("error", (data) {
      if (data != null && data['error'] != null) {
        DialogManager.errorHandler(data['error']);
      }
    });
    socket.on("multipleDevice", _multipleDevice);
    socket.on("chat", _chatHandler);
    socket.on("removeChat", _removeChatHandler);
    socket.on("kicked", _kickedHandler);
  }

  void _multipleDevice(dynamic data) async{
    final router = AppRoute.context;

    if(router != null){
      FirebaseAuth.instance.signOut();
      router.go('/login');
      await DialogManager.showBasicDialog(title: '다른 기기에서 로그인되었어요', content: "다른 기기에 로그인 시도로 인해 로그아웃 되었습니다.", confirmText: "확인");
    }
  }

  void _kickedHandler(dynamic data) {
    try {
      if (data == null || data['roomId'] == null) return;

      final roomId = data['roomId'] as int;
      final room = data['room'] as Map<String, dynamic>?;

      _chat.remove(roomId);
      _my.remove(roomId);
      _lastReadChatId.remove(roomId);
      _loadedChatIds.remove(roomId);
      _joinedRooms.remove(roomId);

      final context = AppRoute.context;
      if (context == null || !context.mounted) {
        notifyListeners();
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        try {
          final router = GoRouter.of(context);
          final currentPath = router.state.path;

          if (currentPath == '/room/:roomId') {
            final currentRoomId = router.state.pathParameters['roomId'];
            if (currentRoomId == roomId.toString()) {
              context.go('/my');
            }
          }

          _showKickedDialog(room);
          _refreshRoomsData(context);
        } catch (e) {
          print('추방 처리 네비게이션 오류: $e');
        }
      });

      notifyListeners();
    } catch (e) {
      print('추방 처리 오류: $e');
      notifyListeners();
    }
  }

  void _showKickedDialog(Map<String, dynamic>? room) {
    try {
      final roomName = room?['roomName']?.toString() ?? '알 수 없는 방';
      final local = room?['local']?.toString() ?? '알 수 없는 지역';

      DialogManager.showBasicDialog(
        title: '방에서 추방되었습니다',
        content: '$local 지역의 "$roomName" 채팅방에서\n추방되었어요.',
        confirmText: '확인',
      );
    } catch (e) {
      print('추방 다이얼로그 오류: $e');
      DialogManager.showBasicDialog(
        title: '방에서 추방되었습니다',
        content: '채팅방에서 추방되었습니다.',
        confirmText: '확인',
      );
    }
  }

  void _refreshRoomsData(BuildContext context) {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            final roomsProvider = context.read<RoomsProvider>();
            // 🔧 전체 재초기화 대신 특정 방만 업데이트
            _syncWithRoomsProvider(roomsProvider);
          } catch (e) {
            print('방 목록 동기화 오류: $e');
          }
        }
      });
    } catch (e) {
      print('방 목록 새로고침 스케줄링 오류: $e');
    }
  }

  void _syncWithRoomsProvider(RoomsProvider roomsProvider) {
    final allRoomIds = <int>[
      ...?roomsProvider.rooms?.keys,
      ...?roomsProvider.quickRooms?.keys,
    ];

    // ChatProvider에는 있지만 RoomsProvider에는 없는 방들 제거
    final chatRoomIds = {..._chat.keys, ..._my.keys};
    final toRemove = chatRoomIds.where((id) => !allRoomIds.contains(id));

    for (final roomId in toRemove) {
      print('🗑️ 동기화: 방 $roomId 제거');
      _chat.remove(roomId);
      _my.remove(roomId);
      _lastReadChatId.remove(roomId);
      _loadedChatIds.remove(roomId);
      _joinedRooms.remove(roomId);
    }

    notifyListeners();
  }

  void _removeChatHandler(dynamic data) {
    try {
      if (data == null) return;

      final roomId = data['roomId'] as int?;
      final chatId = data['chatId'] as int?;

      if (roomId == null || chatId == null) return;

      final chats = _chat[roomId];
      if (chats == null || chats.isEmpty) return;

      final index = chats.indexWhere((e) => e.chatId == chatId);
      if (index != -1 && index < chats.length) {
        chats[index].type = ChatType.removed;
        notifyListeners();
      }
    } catch (e) {
      print('채팅 삭제 처리 오류: $e');
    }
  }

  void _chatHandler(dynamic data) {
    try {
      if (data == null) return;

      final Chat chat = Chat.fromJson(json: data);
      final int roomId = chat.roomId;

      _loadedChatIds.putIfAbsent(roomId, () => <int>{});
      if (_loadedChatIds[roomId]!.contains(chat.chatId)) {
        return;
      }

      _chat.putIfAbsent(roomId, () => <Chat>[]);

      // 🔧 수정: 올바른 위치에 삽입 (시간순 정렬 유지)
      final chats = _chat[roomId]!;
      int insertIndex = chats.length;

      // 이진 탐색으로 삽입 위치 찾기
      for (int i = chats.length - 1; i >= 0; i--) {
        if (chats[i].createAt.isBefore(chat.createAt) ||
            chats[i].createAt.isAtSameMomentAs(chat.createAt)) {
          insertIndex = i + 1;
          break;
        }
      }

      chats.insert(insertIndex, chat);
      _loadedChatIds[roomId]!.add(chat.chatId);

      final context = AppRoute.context;
      if (context?.mounted == true) {
        try {
          final state = GoRouter.of(context!).state;
          if (state.path == '/room/:roomId' &&
              state.pathParameters['roomId'] == roomId.toString()) {
            // 현재 방에 있으면 즉시 lastRead 업데이트하고 배지 갱신
            updateMyLastReadInServer(roomId);
          } else {
            // 다른 방에 있으면 unread 증가
            final myData = _my[roomId];
            if (myData != null) {
              final currentCount = myData['unreadCount'] as int? ?? 0;
              myData['unreadCount'] = currentCount + 1;
              _updateBadgeImmediately();
            }
          }
        } catch (e) {
          print('채팅 핸들러 라우터 처리 오류: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      print('채팅 핸들러 오류: $e');
    }
  }

  // 🔧 개선된 메서드: updateMyLastReadInServer
  Future<void> updateMyLastReadInServer(int roomId) async {
    try {
      print('🔄 updateMyLastReadInServer 시작 (roomId: $roomId)');

      final chats = _chat[roomId];
      if (chats == null || chats.isEmpty) {
        print('⚠️ 채팅이 없어서 lastRead 업데이트를 건너뜁니다');
        return;
      }

      // 🔧 수정: reduce를 사용하여 가장 큰 chatId를 가진 채팅 찾기
      final latestChat = chats.reduce((a, b) => a.chatId > b.chatId ? a : b);

      if (latestChat.chatId <= 0) {
        print('⚠️ 유효하지 않은 chatId입니다: ${latestChat.chatId}');
        return;
      }

      // 현재 lastRead와 비교하여 필요한 경우에만 업데이트
      final currentLastRead = _my[roomId]?['lastRead'] as int? ?? 0;
      if (currentLastRead >= latestChat.chatId) {
        print('⚠️ 이미 최신 상태입니다 (current: $currentLastRead, new: ${latestChat.chatId})');
        return;
      }

      print('📊 업데이트 예정: $currentLastRead -> ${latestChat.chatId}');

      // 로컬 상태 업데이트
      final myData = _my[roomId];
      if (myData != null) {
        myData['lastRead'] = latestChat.chatId;
        myData['unreadCount'] = 0;
        _lastReadChatId[roomId] = latestChat.chatId;
      }

      _updateBadgeImmediately();
      notifyListeners();

      // 서버 업데이트
      await _sendLastReadToServerSync(roomId, latestChat.chatId);

      print('✅ updateMyLastReadInServer 완료');
    } catch (e) {
      print('❌ updateMyLastReadInServer 오류: $e');
    }
  }

  // 🔧 새로운 메서드: 동기 서버 업데이트
  Future<void> _sendLastReadToServerSync(int roomId, int lastReadId) async {
    try {
      print('📡 서버에 lastRead 업데이트 전송: roomId=$roomId, lastReadId=$lastReadId');

      final response = await serverManager.put(
          'roomMember/lastread/$roomId?lastRead=$lastReadId'
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ 서버 lastRead 업데이트 성공');
      } else {
        print('⚠️ 서버 lastRead 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 서버 lastRead 업데이트 오류: $e');
    }
  }

  void _sortChatsByCreateTime(int roomId) {
    final chats = _chat[roomId];
    if (chats == null || chats.isEmpty) return;

    try {
      chats.sort((a, b) => a.createAt.compareTo(b.createAt));
      print('✅ 채팅 리스트 정렬 완료 (roomId: $roomId)');
    } catch (e) {
      print('❌ 채팅 리스트 정렬 오류: $e');
    }
  }

  // 즉시 배지 업데이트
  void _updateBadgeImmediately() {
    try {
      final badge = _calculateTotalUnreadCount();
      AppBadgePlus.updateBadge(badge);
      print('배지 업데이트: $badge');
    } catch (e) {
      print('즉시 배지 업데이트 오류: $e');
    }
  }

  // 총 unread count 계산
  int _calculateTotalUnreadCount() {
    return _my.entries.fold<int>(0, (sum, entry) {
      final unreadCount = entry.value['unreadCount'] as int? ?? 0;
      return sum + unreadCount;
    });
  }

  Future<bool> setChats(int roomId) async {
    if (_socketLoading) {
      print('❌ setChats 중단: 이미 로딩 중');
      return false;
    }

    _socketLoading = true;
    notifyListeners();
    print('🚀 setChats 시작 (roomId: $roomId)');

    try {
      final response = await serverManager.get('chat/chat?roomId=$roomId');
      print('📡 서버 응답: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final chatsData = data['chats'] as List? ?? [];
        final lastReadChatId = data['lastReadChatId'] as int?;
        final unreadCount = data['unreadCount'] as int? ?? 0;

        print('📊 초기 데이터:');
        print('- 채팅 수: ${chatsData.length}');
        print('- lastReadChatId: $lastReadChatId');
        print('- unreadCount: $unreadCount');

        _lastReadChatId[roomId] = lastReadChatId;

        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        // 🔧 수정: 채팅을 시간순으로 정렬
        newChats.sort((a, b) => a.createAt.compareTo(b.createAt));

        if (newChats.isNotEmpty) {
          print('- 가장 오래된 채팅: ID=${newChats.first.chatId}, createAt=${newChats.first.createAt}');
          print('- 가장 최신 채팅: ID=${newChats.last.chatId}, createAt=${newChats.last.createAt}');
        }

        _chat[roomId] = newChats;
        _loadedChatIds[roomId] = newChats.map((chat) => chat.chatId).toSet();

        final myData = _my[roomId];
        if (myData != null) {
          myData['unreadCount'] = unreadCount;
          // 🔧 수정: 서버에서 받은 lastReadChatId로 설정
          if (lastReadChatId != null) {
            myData['lastRead'] = lastReadChatId;
          }
        }

        // 배지 업데이트
        _updateBadgeImmediately();

        notifyListeners();
        print('✅ setChats 성공');
        return true;
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ setChats 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
      print('🔄 setChats 완료');
    }

    return false;
  }

  Future<bool> loadChatsBefore(int roomId) async {
    if (_socketLoading) {
      print('❌ loadChatsBefore 중단: 이미 로딩 중');
      return false;
    }

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) {
      print('❌ loadChatsBefore 중단: 현재 채팅 없음');
      return false;
    }

    try {
      _socketLoading = true;
      notifyListeners();
      print('🚀 loadChatsBefore 시작 (roomId: $roomId)');

      final oldestChatId = currentChats.first.chatId;
      print('📋 현재 상태:');
      print('- 현재 채팅 수: ${currentChats.length}');
      print('- 가장 오래된 chatId: $oldestChatId');
      print('- 가장 오래된 채팅 시간: ${currentChats.first.createAt}');

      final response = await serverManager.get('chat/chatsBefore?roomId=$roomId&lastChatId=$oldestChatId');
      print('📡 서버 응답: ${response.statusCode}');

      if (response.statusCode == 200 && response.data is List) {
        final chatsData = List.from(response.data);
        print('📊 새로 받은 데이터: ${chatsData.length}개');

        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        if (newChats.isNotEmpty) {
          print('- 새 채팅 범위: ${newChats.first.chatId} ~ ${newChats.last.chatId}');
          print('- 새 채팅 시간 범위: ${newChats.first.createAt} ~ ${newChats.last.createAt}');

          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          print('- 중복 제거 후: ${filteredChats.length}개');

          if (filteredChats.isNotEmpty) {
            currentChats.insertAll(0, filteredChats);
            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }

            print('✅ 채팅 추가 완료');
            print('- 총 채팅 수: ${currentChats.length}');
            print('- 새로운 가장 오래된 채팅: ID=${currentChats.first.chatId}, createAt=${currentChats.first.createAt}');

            final hasMore = chatsData.length >= 20;
            print('🔍 hasMore 판단: $hasMore (받은 데이터 수: ${chatsData.length})');
            notifyListeners();
            return hasMore;
          } else {
            print('⚠️ 모든 채팅이 중복됨');
          }
        } else {
          print('⚠️ 새 채팅 없음');
        }
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ loadChatsBefore 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
      print('🔄 loadChatsBefore 완료');
    }

    return false;
  }

  Future<bool> loadChatsAfter(int roomId) async {
    if (_socketLoading) {
      print('❌ loadChatsAfter 중단: 이미 로딩 중');
      return false;
    }

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) {
      print('❌ loadChatsAfter 중단: 현재 채팅 없음');
      return false;
    }

    try {
      _socketLoading = true;
      notifyListeners();
      print('🚀 loadChatsAfter 시작 (roomId: $roomId)');

      final sortedChats = [...currentChats]..sort((a, b) => a.createAt.compareTo(b.createAt));
      final newestChatId = sortedChats.last.chatId;

      print('📋 현재 상태:');
      print('- 현재 채팅 수: ${currentChats.length}');
      print('- 가장 최신 chatId: $newestChatId');
      print('- 가장 최신 채팅 시간: ${sortedChats.last.createAt}');

      final response = await serverManager.get('chat/chatsAfter?roomId=$roomId&lastChatId=$newestChatId');
      print('📡 서버 응답: ${response.statusCode}');

      if (response.statusCode == 200 && response.data is List) {
        final chatsData = response.data as List;
        print('📊 새로 받은 데이터: ${chatsData.length}개');

        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        if (newChats.isNotEmpty) {
          print('- 새 채팅 범위: ${newChats.first.chatId} ~ ${newChats.last.chatId}');
          print('- 새 채팅 시간 범위: ${newChats.first.createAt} ~ ${newChats.last.createAt}');

          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          print('- 중복 제거 후: ${filteredChats.length}개');

          if (filteredChats.isNotEmpty) {
            currentChats.insertAll(0, filteredChats);
            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }

            print('✅ 채팅 추가 완료');
            print('- 총 채팅 수: ${currentChats.length}');

            updateMyLastReadInServer(roomId);

            final hasMore = chatsData.length >= 20;
            print('🔍 hasMore 판단: $hasMore (받은 데이터 수: ${chatsData.length})');
            notifyListeners();
            return hasMore;
          } else {
            print('⚠️ 모든 채팅이 중복됨');
          }
        } else {
          print('⚠️ 새 채팅 없음');
        }
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ loadChatsAfter 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
      print('🔄 loadChatsAfter 완료');
    }

    return false;
  }

  Future<void> setMyRoom(int roomId) async {
    try {
      final myData = await serverManager.get('roomMember/my/$roomId');

      if (myData.statusCode == 200 && myData.data != null) {
        final data = myData.data as Map<String, dynamic>;
        _my[roomId] = data;

        final lastRead = data['lastRead'] as int?;
        if (lastRead != null) {
          _lastReadChatId[roomId] = lastRead;
        }

        // 배지 업데이트
        _updateBadgeImmediately();

        notifyListeners();
      }
    } catch (e) {
      print('내 방 정보 로드 오류: $e');
    }
  }

  void onReconnect() async {
    final rooms = AppRoute.context?.read<RoomsProvider>().rooms;
    if (rooms == null || rooms.isEmpty) return;

    for (final roomId in rooms.keys) {
      if (_joinedRooms.contains(roomId)) continue;

      try {
        await onReconnectChat(roomId);
        await setMyRoom(roomId);
        socket.emit('join', roomId);
        _joinedRooms.add(roomId);
      } catch (e) {
        print('방 재연결 오류 (roomId: $roomId): $e');
      }
    }
    notifyListeners();
  }

  Future<void> onReconnectChat(int roomId) async {
    try {
      final myData = _my[roomId];
      if (myData == null) return;

      final lastChatId = myData['lastRead'] as int? ?? 0;
      final response = await serverManager.get('chat/reconnect?roomId=$roomId&lastChatId=$lastChatId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final chatsData = data['data'] as List? ?? [];
        final unreadCount = data['unreadCount'] as int? ?? 0;

        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        _loadedChatIds.putIfAbsent(roomId, () => <int>{});
        _chat.putIfAbsent(roomId, () => <Chat>[]);
        myData['unreadCount'] = unreadCount;

        for (Chat chat in newChats) {
          if (!_loadedChatIds[roomId]!.contains(chat.chatId)) {
            _chat[roomId]!.add(chat);
            _loadedChatIds[roomId]!.add(chat.chatId);
          }
        }

        // 배지 업데이트
        _updateBadgeImmediately();

        notifyListeners();
      }
    } catch (e) {
      print('채팅 재연결 오류 (roomId: $roomId): $e');
    }
  }

  Future<void> removeRoom(int roomId) async {
    try {
      _joinedRooms.remove(roomId);
      leaveRoom(roomId);
      _chat.remove(roomId);
      _my.remove(roomId);
      _lastReadChatId.remove(roomId);
      _loadedChatIds.remove(roomId);

      // 배지 업데이트
      _updateBadgeImmediately();

      final context = AppRoute.context;
      if (context?.mounted == true) {
        await context!.read<RoomsProvider>().roomInitialize();
      }
    } catch (e) {
      print('방 제거 오류: $e');
    }
  }

  void changedMyGrade(int roomId, int grade) {
    try {
      final myData = _my[roomId];
      if (myData != null) {
        myData['grade'] = grade;
        notifyListeners();
      }
    } catch (e) {
      print('등급 변경 오류: $e');
    }
  }

  Future<void> refreshRoomFromBackground(int roomId) async {
    try {
      if (_joinedRooms.contains(roomId)) {
        await onReconnectChat(roomId);
        await setMyRoom(roomId);
      } else {
        await joinRoom(roomId);
      }
    } catch (e) {
      print('백그라운드 복귀 새로고침 오류 (roomId: $roomId): $e');
    }
  }

  void readReset(int roomId) {
    try {
      final myData = _my[roomId];
      if (myData != null) {
        myData['unreadCount'] = 0;
      }
      _updateBadgeImmediately();
    } catch (e) {
      print('읽음 상태 리셋 오류: $e');
    }
  }

  // 기존 setBadge 메서드 (호환성 유지)
  void setBadge() {
    _updateBadgeImmediately();
  }

  String getLastChat(int roomId) {
    try {
      final chats = _chat[roomId];
      if (chats == null || chats.isEmpty) {
        return '아직 채팅이 없어요';
      }

      final latestChat = chats.reduce((a, b) => a.chatId > b.chatId ? a : b);
      return _getChatText(latestChat);
    } catch (e) {
      print('getLastChat 오류 (roomId: $roomId): $e');
      return '채팅을 불러오는 중...';
    }
  }

  /// 채팅 텍스트 생성
  String _getChatText(Chat latestChat) {
    switch (latestChat.type) {
      case ChatType.text:
        return latestChat.contents!;
      case ChatType.image:
        return '사진';
      case ChatType.schedule:
        return '일정';
      default:
        return '삭제된 메시지 입니다';
    }
  }

  int getUnreadCount(List<int>? roomIds){
    if(roomIds == null) return 0;

    int sub = 0;
    for(int roomId in roomIds){
       final int? uc = _my[roomId]?['unreadCount'];
       if(uc != null) {
          sub += uc;
       }
    }
    return sub;
  }

}