import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

class ChatProvider extends ChangeNotifier {
  final SocketManager socket = SocketManager();

  // 기본 상태
  bool _isInitialized = false;
  bool _socketLoading = false;
  bool _isReconnecting = false; // 🔧 재연결 상태 추가

  // 데이터 저장소
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};
  final Set<int> _joinedRooms = {};
  final Map<int, Set<int>> _loadedChatIds = {};

  // 🔧 재연결 관리
  final Set<int> _pendingReconnectRooms = {};
  Timer? _reconnectTimeoutTimer;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get socketLoading => _socketLoading || _isReconnecting; // 🔧 재연결 상태도 포함
  Map<int, List<Chat>> get chat => _chat;
  Map<int, Map<String, dynamic>> get my => _my;
  Set<int> get joinedRooms => _joinedRooms;

  // 소켓 초기화 및 채팅 데이터 로드
  Future<void> initializeSocket() async {
    if (_isInitialized) return;

    try {
      print('🚀 채팅 시스템 초기화 시작');
      _socketLoading = true;
      notifyListeners();

      await socket.connect();
      _setSocketListeners();
      await _loadAllRoomChats();

      _isInitialized = true;
      print('✅ 채팅 시스템 초기화 완료');
    } catch (e) {
      print('❌ 채팅 시스템 초기화 실패: $e');
    } finally {
      _socketLoading = false; // 🔧 반드시 false로 설정
      notifyListeners();
    }
  }

  // 모든 방의 채팅 데이터 로드
  Future<void> _loadAllRoomChats() async {
    try {
      final roomsProvider = AppRoute.context?.read<RoomsProvider>();
      if (roomsProvider == null) return;

      final allRoomIds = <int>[
        ...?roomsProvider.rooms?.keys,
        ...?roomsProvider.quickRooms?.keys,
      ];

      print('📊 로드할 방 목록: $allRoomIds');

      // 🔧 병렬 처리로 성능 개선, 하지만 안전하게
      final futures = allRoomIds.map((roomId) => _joinRoomSafely(roomId));
      await Future.wait(futures, eagerError: false);

      _updateBadge();
    } catch (e) {
      print('❌ 방 채팅 로드 실패: $e');
    }
  }

  // 🔧 안전한 방 조인
  Future<void> _joinRoomSafely(int roomId) async {
    try {
      await _joinRoom(roomId);
    } catch (e) {
      print('❌ 방 조인 실패 ($roomId): $e');
      // 개별 방 실패는 전체를 막지 않음
    }
  }

  // 방 참가 및 데이터 로드
  Future<void> _joinRoom(int roomId) async {
    if (_joinedRooms.contains(roomId)) return;

    try {
      print('🔗 방 조인: $roomId');

      // 1. 내 정보 로드
      await _loadMyRoomData(roomId);

      // 2. 채팅 데이터 로드
      await _loadRoomChats(roomId);

      // 3. 소켓 조인
      socket.emit('join', roomId);
      _joinedRooms.add(roomId);

      print('✅ 방 조인 완료: $roomId');
    } catch (e) {
      print('❌ 방 조인 실패 ($roomId): $e');
      throw e; // 상위로 에러 전파
    }
  }

  // 내 방 정보 로드
  Future<void> _loadMyRoomData(int roomId) async {
    try {
      final response = await serverManager.get('roomMember/my/$roomId');
      if (response.statusCode == 200 && response.data != null) {
        _my[roomId] = Map<String, dynamic>.from(response.data);
        print('✅ 내 방 정보 로드: $roomId');
      } else {
        throw Exception('방 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 내 방 정보 로드 실패 ($roomId): $e');
      throw e;
    }
  }

  // 방 채팅 데이터 로드
  Future<void> _loadRoomChats(int roomId) async {
    try {
      final response = await serverManager.get('chat/chat?roomId=$roomId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final chatsData = data['chats'] as List? ?? [];
        final unreadCount = data['unreadCount'] as int? ?? 0;

        // 채팅 데이터 변환 및 정렬
        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();
        newChats.sort((a, b) => a.createAt.compareTo(b.createAt));

        _chat[roomId] = newChats;
        _loadedChatIds[roomId] = newChats.map((chat) => chat.chatId).toSet();

        // unread count 업데이트
        if (_my[roomId] != null) {
          _my[roomId]!['unreadCount'] = unreadCount;
        }

        print('✅ 채팅 데이터 로드: $roomId (${newChats.length}개)');
      } else {
        throw Exception('채팅 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 채팅 데이터 로드 실패 ($roomId): $e');
      throw e;
    }
  }

  // 소켓 리스너 설정
  void _setSocketListeners() {
    socket.on("error", _handleError);
    socket.on("multipleDevice", _handleMultipleDevice);
    socket.on("chat", _handleNewChat);
    socket.on("removeChat", _handleRemoveChat);
    socket.on("kicked", _handleKicked);
  }

  void _handleError(dynamic data) {
    if (data != null && data['error'] != null) {
      DialogManager.errorHandler(data['error']);
    }
  }

  void _handleMultipleDevice(dynamic data) async {
    final router = AppRoute.context;
    if (router != null) {
      FirebaseAuth.instance.signOut();
      router.go('/login');
      await DialogManager.showBasicDialog(
          title: '다른 기기에서 로그인되었어요',
          content: "다른 기기에 로그인 시도로 인해 로그아웃 되었습니다.",
          confirmText: "확인"
      );
    }
  }

  void _handleNewChat(dynamic data) {
    try {
      if (data == null) return;

      final Chat chat = Chat.fromJson(json: data);
      final roomId = chat.roomId;

      // 중복 체크
      _loadedChatIds.putIfAbsent(roomId, () => <int>{});
      if (_loadedChatIds[roomId]!.contains(chat.chatId)) return;

      // 채팅 추가
      _chat.putIfAbsent(roomId, () => <Chat>[]);
      _chat[roomId]!.add(chat);
      _chat[roomId]!.sort((a, b) => a.createAt.compareTo(b.createAt));
      _loadedChatIds[roomId]!.add(chat.chatId);

      // 읽음 상태 처리
      final context = AppRoute.context;
      if (context?.mounted == true) {
        final router = GoRouter.of(context!);
        final currentPath = router.state.path;
        final currentRoomId = router.state.pathParameters['roomId'];

        if (currentPath == '/room/:roomId' &&
            currentRoomId == roomId.toString()) {
          // 현재 방에 있으면 즉시 읽음 처리
          updateLastRead(roomId);
        } else {
          // 다른 곳에 있으면 unread 증가
          final myData = _my[roomId];
          if (myData != null) {
            final currentCount = myData['unreadCount'] as int? ?? 0;
            myData['unreadCount'] = currentCount + 1;
            _updateBadge();
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ 새 채팅 처리 오류: $e');
    }
  }

  void _handleRemoveChat(dynamic data) {
    try {
      if (data == null) return;

      final roomId = data['roomId'] as int?;
      final chatId = data['chatId'] as int?;

      if (roomId == null || chatId == null) return;

      final chats = _chat[roomId];
      if (chats == null) return;

      final index = chats.indexWhere((e) => e.chatId == chatId);
      if (index != -1) {
        chats[index].type = ChatType.removed;
        notifyListeners();
      }
    } catch (e) {
      print('❌ 채팅 삭제 처리 오류: $e');
    }
  }

  void _handleKicked(dynamic data) {
    try {
      if (data == null || data['roomId'] == null) return;

      final roomId = data['roomId'] as int;

      // 데이터 정리
      _chat.remove(roomId);
      _my.remove(roomId);
      _loadedChatIds.remove(roomId);
      _joinedRooms.remove(roomId);

      // UI 업데이트
      final context = AppRoute.context;
      if (context?.mounted == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context!.mounted) {
            final router = GoRouter.of(context);
            final currentPath = router.state.path;
            final currentRoomId = router.state.pathParameters['roomId'];

            if (currentPath == '/room/:roomId' &&
                currentRoomId == roomId.toString()) {
              context.go('/my');
            }

            DialogManager.showBasicDialog(
              title: '방에서 추방되었습니다',
              content: '채팅방에서 추방되었습니다.',
              confirmText: '확인',
            );
          }
        });
      }

      notifyListeners();
    } catch (e) {
      print('❌ 추방 처리 오류: $e');
    }
  }

  // 소켓 연결 성공 시 호출
  void onSocketConnected() {
    print('✅ ChatProvider: 소켓 연결됨');
    _isReconnecting = false;
    notifyListeners();
  }

  // 🔧 개선된 소켓 재연결 처리
  void onSocketReconnected() {
    if (_isReconnecting) return; // 이미 재연결 중이면 중복 실행 방지

    _isReconnecting = true;
    _pendingReconnectRooms.clear();
    notifyListeners();

    print('🔄 소켓 재연결 처리 시작');

    // 타임아웃 설정 (30초)
    _reconnectTimeoutTimer?.cancel();
    _reconnectTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isReconnecting) {
        print('⏰ 재연결 타임아웃 - 강제 완료');
        _finishReconnect();
      }
    });

    _processReconnection();
  }

  // 🔧 재연결 프로세스
  Future<void> _processReconnection() async {
    try {
      final roomIds = _joinedRooms.toList();
      print('🔄 재연결할 방 목록: $roomIds');

      if (roomIds.isEmpty) {
        _finishReconnect();
        return;
      }

      _pendingReconnectRooms.addAll(roomIds);

      // 병렬로 재연결 처리, 하지만 제한된 동시성
      const batchSize = 3; // 동시에 3개씩만 처리
      for (int i = 0; i < roomIds.length; i += batchSize) {
        final batch = roomIds.skip(i).take(batchSize);
        final futures = batch.map((roomId) => _reconnectRoom(roomId));
        await Future.wait(futures, eagerError: false);
      }

      _finishReconnect();
    } catch (e) {
      print('❌ 재연결 프로세스 오류: $e');
      _finishReconnect();
    }
  }

  // 🔧 개별 방 재연결
  Future<void> _reconnectRoom(int roomId) async {
    try {
      await refreshRoomData(roomId);
      _pendingReconnectRooms.remove(roomId);
      print('✅ 방 재연결 완료: $roomId');
    } catch (e) {
      print('❌ 방 재연결 실패 ($roomId): $e');
      _pendingReconnectRooms.remove(roomId);
    }
  }

  // 🔧 재연결 완료
  void _finishReconnect() {
    _reconnectTimeoutTimer?.cancel();
    _isReconnecting = false;
    _pendingReconnectRooms.clear();
    notifyListeners();
    print('✅ 소켓 재연결 처리 완료');
  }

  // 특정 방 조인 (Public)
  Future<void> joinRoom(int roomId) async {
    try {
      await _joinRoom(roomId);
      notifyListeners();
    } catch (e) {
      print('❌ 방 조인 오류 ($roomId): $e');
    }
  }

  // 방 데이터 새로고침 (Public)
  Future<void> refreshRoomData(int roomId) async {
    try {
      await _loadMyRoomData(roomId);

      // 최신 채팅만 가져오기
      final myData = _my[roomId];
      if (myData != null) {
        final lastRead = myData['lastRead'] as int? ?? 0;
        final response = await serverManager.get(
            'chat/reconnect?roomId=$roomId&lastChatId=$lastRead'
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final chatsData = data['data'] as List? ?? [];
          final unreadCount = data['unreadCount'] as int? ?? 0;

          final newChats = chatsData
              .map((e) => Chat.fromJson(json: e))
              .toList();

          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          _chat.putIfAbsent(roomId, () => <Chat>[]);

          for (Chat chat in newChats) {
            if (!_loadedChatIds[roomId]!.contains(chat.chatId)) {
              _chat[roomId]!.add(chat);
              _loadedChatIds[roomId]!.add(chat.chatId);
            }
          }

          _chat[roomId]!.sort((a, b) => a.createAt.compareTo(b.createAt));
          myData['unreadCount'] = unreadCount;
          _updateBadge();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ 방 데이터 새로고침 오류 ($roomId): $e');
      throw e;
    }
  }

  // 읽음 상태 업데이트
  Future<void> updateLastRead(int roomId) async {
    try {
      final chats = _chat[roomId];
      if (chats == null || chats.isEmpty) return;

      final latestChat = chats.reduce((a, b) => a.chatId > b.chatId ? a : b);
      final myData = _my[roomId];

      if (myData != null) {
        final currentLastRead = myData['lastRead'] as int? ?? 0;
        if (currentLastRead >= latestChat.chatId) return;

        // 로컬 업데이트
        myData['lastRead'] = latestChat.chatId;
        myData['unreadCount'] = 0;

        _updateBadge();
        notifyListeners();

        // 서버 업데이트
        await serverManager.put(
            'roomMember/lastread/$roomId?lastRead=${latestChat.chatId}'
        );
      }
    } catch (e) {
      print('❌ 읽음 상태 업데이트 오류: $e');
    }
  }

  // 이전 채팅 로드 (위로 스크롤)
  Future<bool> loadChatsBefore(int roomId) async {
    if (_socketLoading || _isReconnecting) return false;

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) return false;

    try {
      _socketLoading = true;
      notifyListeners();

      final oldestChatId = currentChats.first.chatId;
      final response = await serverManager.get(
          'chat/chatsBefore?roomId=$roomId&lastChatId=$oldestChatId'
      );

      if (response.statusCode == 200 && response.data is List) {
        final chatsData = List.from(response.data);
        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        if (newChats.isNotEmpty) {
          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          if (filteredChats.isNotEmpty) {
            currentChats.insertAll(0, filteredChats);
            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }
            notifyListeners();
            return chatsData.length >= 20;
          }
        }
      }
    } catch (e) {
      print('❌ 이전 채팅 로드 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }

    return false;
  }

  // 이후 채팅 로드 (아래로 스크롤)
  Future<bool> loadChatsAfter(int roomId) async {
    if (_socketLoading || _isReconnecting) return false;

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) return false;

    try {
      _socketLoading = true;
      notifyListeners();

      final sortedChats = [...currentChats]..sort((a, b) => a.createAt.compareTo(b.createAt));
      final newestChatId = sortedChats.last.chatId;

      final response = await serverManager.get(
          'chat/chatsAfter?roomId=$roomId&lastChatId=$newestChatId'
      );

      if (response.statusCode == 200 && response.data is List) {
        final chatsData = response.data as List;
        final newChats = chatsData
            .map((e) => Chat.fromJson(json: e))
            .toList();

        if (newChats.isNotEmpty) {
          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          if (filteredChats.isNotEmpty) {
            currentChats.addAll(filteredChats);
            currentChats.sort((a, b) => a.createAt.compareTo(b.createAt));

            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }

            // 자동으로 읽음 처리
            updateLastRead(roomId);
            notifyListeners();
            return chatsData.length >= 20;
          }
        }
      }
    } catch (e) {
      print('❌ 이후 채팅 로드 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }

    return false;
  }

  // 방 나가기
  Future<void> removeRoom(int roomId) async {
    try {
      _joinedRooms.remove(roomId);
      _pendingReconnectRooms.remove(roomId);
      socket.emit('leave', {'roomId': roomId});
      _chat.remove(roomId);
      _my.remove(roomId);
      _loadedChatIds.remove(roomId);
      _updateBadge();
      notifyListeners();
    } catch (e) {
      print('❌ 방 나가기 오류: $e');
    }
  }

  // 백그라운드 복귀시 새로고침
  Future<void> refreshRoomFromBackground(int roomId) async {
    try {
      if (_joinedRooms.contains(roomId)) {
        await refreshRoomData(roomId);
      }
    } catch (e) {
      print('❌ 백그라운드 새로고침 오류 ($roomId): $e');
    }
  }

  // 유틸리티 메서드들
  bool isJoined(int roomId) => _joinedRooms.contains(roomId) && !_pendingReconnectRooms.contains(roomId);

  // 🔧 데이터 준비 상태 확인
  bool isRoomDataReady(int roomId) {
    return _my[roomId] != null &&
        _chat[roomId] != null &&
        _joinedRooms.contains(roomId) &&
        !_pendingReconnectRooms.contains(roomId);
  }

  Chat? latestChatTime(int roomId) {
    final chats = _chat[roomId];
    if (chats == null || chats.isEmpty) return null;
    return chats.reduce((a, b) => a.createAt.isAfter(b.createAt) ? a : b);
  }

  String getLastChat(int roomId) {
    try {
      final chats = _chat[roomId];
      if (chats == null || chats.isEmpty) return '아직 채팅이 없어요';

      final latestChat = chats.reduce((a, b) => a.chatId > b.chatId ? a : b);

      switch (latestChat.type) {
        case ChatType.text:
          return latestChat.contents ?? '알수없는 채팅';
        case ChatType.image:
          return '사진';
        case ChatType.schedule:
          return '일정';
        default:
          return '삭제된 메시지 입니다';
      }
    } catch (e) {
      return '채팅을 불러오는 중...';
    }
  }

  int getUnreadCount(List<int>? roomIds) {
    if (roomIds == null) return 0;

    int total = 0;
    for (int roomId in roomIds) {
      final unread = _my[roomId]?['unreadCount'] as int? ?? 0;
      total += unread;
    }
    return total;
  }

  void _updateBadge() {
    try {
      final totalUnread = _my.entries.fold<int>(0, (sum, entry) {
        final unreadCount = entry.value['unreadCount'] as int? ?? 0;
        return sum + unreadCount;
      });
      AppBadgePlus.updateBadge(totalUnread);
    } catch (e) {
      print('❌ 배지 업데이트 오류: $e');
    }
  }

  void myMemberUpdate({required int roomId, required String field, required dynamic data}) {
    if (_my.containsKey(roomId) && _my[roomId] != null) {
      _my[roomId]![field] = data;
      if (field == 'unreadCount') {
        _updateBadge();
      }
      notifyListeners();
    }
  }

  void changedMyGrade(int roomId, int grade) {
    final myData = _my[roomId];
    if (myData != null) {
      myData['grade'] = grade;
      notifyListeners();
    }
  }

  void readReset(int roomId) {
    final myData = _my[roomId];
    if (myData != null) {
      myData['unreadCount'] = 0;
      _updateBadge();
    }
  }

  void onDisconnect() {
    _joinedRooms.clear();
    _pendingReconnectRooms.clear();
    _isReconnecting = false;
    _reconnectTimeoutTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimeoutTimer?.cancel();
    super.dispose();
  }
}