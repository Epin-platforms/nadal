import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

class ChatProvider extends ChangeNotifier {
  final SocketManager socket = SocketManager();

  // 기본 상태
  bool _isInitialized = false;
  bool _socketLoading = false;
  bool _isReconnecting = false;

  // 데이터 저장소
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};
  final Set<int> _joinedRooms = {};
  final Map<int, Set<int>> _loadedChatIds = {};

  // 🔧 **수정: 재연결 관리 개선**
  final Set<int> _pendingReconnectRooms = {};
  final Set<int> _failedRooms = {};
  Timer? _reconnectTimeoutTimer;
  Timer? _retryFailedRoomsTimer;

  // 🔧 **수정: 초기화 관리 개선**
  bool _hasInitializedRooms = false;
  bool _socketListenersRegistered = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get socketLoading => _socketLoading || _isReconnecting;
  Map<int, List<Chat>> get chat => _chat;
  Map<int, Map<String, dynamic>> get my => _my;
  Set<int> get joinedRooms => _joinedRooms;

  // 🔧 roomsProvider 준비 완료 후 초기화
  Future<void> initializeAfterRooms(RoomsProvider roomsProvider) async {
    if (_isInitialized) {
      debugPrint('🔄 ChatProvider 이미 초기화됨 - 스킵');
      return;
    }

    try {
      debugPrint('🚀 ChatProvider 초기화 시작 (RoomsProvider 이후)');
      _socketLoading = true;
      notifyListeners();

      // 소켓 연결
      await socket.connect();

      // 방 목록 기반으로 채팅 데이터 로드
      await _loadAllRoomChats(roomsProvider);

      _isInitialized = true;
      _hasInitializedRooms = true;
      debugPrint('✅ ChatProvider 초기화 완료');
    } catch (e) {
      debugPrint('❌ ChatProvider 초기화 실패: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }
  }

  // 🔧 **수정: 안전한 소켓 리스너 등록**
  Future<void> registerSocketListenersSafely() async {
    if (_socketListenersRegistered) {
      debugPrint('🔄 ChatProvider 리스너 이미 등록됨 - 스킵');
      return;
    }

    if (!socket.isReallyConnected) {
      debugPrint('❌ 소켓이 준비되지 않음 - 리스너 등록 실패');
      throw Exception('소켓이 준비되지 않음');
    }

    try {
      debugPrint('🔧 ChatProvider 소켓 리스너 등록 시작');
      await _setSocketListeners();
      _socketListenersRegistered = true;
      debugPrint('✅ ChatProvider 소켓 리스너 등록 완료');
    } catch (e) {
      debugPrint('❌ ChatProvider 리스너 등록 실패: $e');
      throw e;
    }
  }

  // 🔧 RoomsProvider 기반으로 모든 방의 채팅 데이터 로드
  Future<void> _loadAllRoomChats(RoomsProvider roomsProvider) async {
    try {
      final allRoomIds = <int>[
        ...?roomsProvider.rooms?.keys,
        ...?roomsProvider.quickRooms?.keys,
      ];

      debugPrint('📊 로드할 방 목록: $allRoomIds');

      if (allRoomIds.isEmpty) {
        debugPrint('📊 참가한 방이 없음');
        return;
      }

      // 배치 처리로 성능 개선
      await _processRoomsInBatches(allRoomIds, batchSize: 3);
      _updateBadge();
    } catch (e) {
      debugPrint('❌ 방 채팅 로드 실패: $e');
    }
  }

  // 배치 단위로 방 처리
  Future<void> _processRoomsInBatches(List<int> roomIds, {int batchSize = 3}) async {
    for (int i = 0; i < roomIds.length; i += batchSize) {
      final batch = roomIds.skip(i).take(batchSize).toList();
      final futures = batch.map((roomId) => _joinRoomSafely(roomId));
      await Future.wait(futures, eagerError: false);

      // 배치 간 짧은 대기
      if (i + batchSize < roomIds.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  // 안전한 방 조인
  Future<void> _joinRoomSafely(int roomId) async {
    try {
      await _joinRoom(roomId);
      _failedRooms.remove(roomId);
    } catch (e) {
      debugPrint('❌ 방 조인 실패 ($roomId): $e');
      _failedRooms.add(roomId);
    }
  }

  // 방 참가 및 데이터 로드
  Future<void> _joinRoom(int roomId) async {
    if (_joinedRooms.contains(roomId)) return;

    try {
      debugPrint('🔗 방 조인: $roomId');

      // 1. 내 정보 로드
      await _loadMyRoomData(roomId);

      // 2. 채팅 데이터 로드
      await _loadRoomChats(roomId);

      // 3. 소켓 조인
      socket.emit('join', roomId);
      _joinedRooms.add(roomId);

      debugPrint('✅ 방 조인 완료: $roomId');
    } catch (e) {
      debugPrint('❌ 방 조인 실패 ($roomId): $e');
      throw e;
    }
  }

  // 내 방 정보 로드
  Future<void> _loadMyRoomData(int roomId) async {
    try {
      final response = await serverManager.get('roomMember/my/$roomId');
      if (response.statusCode == 200 && response.data != null) {
        _my[roomId] = Map<String, dynamic>.from(response.data);
        debugPrint('✅ 내 방 정보 로드: $roomId');
      } else {
        throw Exception('방 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 내 방 정보 로드 실패 ($roomId): $e');
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

        debugPrint('✅ 채팅 데이터 로드: $roomId (${newChats.length}개)');
      } else {
        throw Exception('채팅 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 채팅 데이터 로드 실패 ($roomId): $e');
      throw e;
    }
  }

  // 소켓 리스너 설정
  Future<void> _setSocketListeners() async {
    if (!socket.isReallyConnected) {
      throw Exception('소켓이 연결되지 않음');
    }

    try {
      // 🔧 **수정: 기존 리스너 제거 (중복 방지)**
      socket.off("error");
      socket.off("multipleDevice");
      socket.off("chat");
      socket.off("removeChat");
      socket.off("kicked");

      // 🔧 **수정: 새 리스너 등록 (ChatProvider 전용 메서드 사용)**
      socket.onChatEvent("error", _handleError);
      socket.onChatEvent("multipleDevice", _handleMultipleDevice);
      socket.onChatEvent("chat", _handleNewChat);
      socket.onChatEvent("removeChat", _handleRemoveChat);
      socket.onChatEvent("kicked", _handleKicked);

      debugPrint('✅ ChatProvider 소켓 리스너 설정 완료');
    } catch (e) {
      debugPrint('❌ ChatProvider 소켓 리스너 설정 실패: $e');
      throw e;
    }
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

      // 🔧 **수정: 중복 체크 개선**
      _loadedChatIds.putIfAbsent(roomId, () => <int>{});
      if (_loadedChatIds[roomId]!.contains(chat.chatId)) {
        debugPrint('⚠️ 중복 채팅 무시: ${chat.chatId}');
        return;
      }

      // 채팅 추가
      _chat.putIfAbsent(roomId, () => <Chat>[]);
      _chat[roomId]!.add(chat);
      _chat[roomId]!.sort((a, b) => a.createAt.compareTo(b.createAt));
      _loadedChatIds[roomId]!.add(chat.chatId);

      // 🔧 **수정: 읽음 상태 처리 개선**
      final context = AppRoute.context;
      if (context?.mounted == true) {
        final router = GoRouter.of(context!);
        final currentPath = router.state.path;
        final currentRoomId = router.state.pathParameters['roomId'];

        if (currentPath == '/room/:roomId' &&
            currentRoomId == roomId.toString()) {
          // 현재 방에 있으면 즉시 읽음 처리 (디바운싱 적용)
          _scheduleLastReadUpdate(roomId);
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
      debugPrint('❌ 새 채팅 처리 오류: $e');
    }
  }

  // 🔧 **추가: lastRead 업데이트 디바운싱**
  Timer? _lastReadUpdateTimer;
  void _scheduleLastReadUpdate(int roomId) {
    _lastReadUpdateTimer?.cancel();
    _lastReadUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      updateLastRead(roomId);
    });
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
      debugPrint('❌ 채팅 삭제 처리 오류: $e');
    }
  }

  void _handleKicked(dynamic data) {
    try {
      if (data == null || data['roomId'] == null) return;

      final roomId = data['roomId'] as int;

      // 🔧 **수정: 데이터 정리 개선**
      _cleanupRoomData(roomId);

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
              context.read<HomeProvider>().setMenu(0);
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
      debugPrint('❌ 추방 처리 오류: $e');
    }
  }

  // 🔧 **추가: 방 데이터 정리 메서드**
  void _cleanupRoomData(int roomId) {
    _chat.remove(roomId);
    _my.remove(roomId);
    _loadedChatIds.remove(roomId);
    _joinedRooms.remove(roomId);
    _pendingReconnectRooms.remove(roomId);
    _failedRooms.remove(roomId);
    _updateBadge();
  }

  // 소켓 연결 성공 시 호출
  void onSocketConnected() {
    debugPrint('✅ ChatProvider: 소켓 연결됨');
    _isReconnecting = false;
    _socketListenersRegistered = false;
    notifyListeners();
  }

  // 🔧 **수정: 개선된 소켓 재연결 처리 - 백그라운드 복귀 시에만 실행**
  void onSocketReconnected() {
    if (_isReconnecting) return;

    _isReconnecting = true;
    _socketListenersRegistered = false;
    _pendingReconnectRooms.clear();
    notifyListeners();

    debugPrint('🔄 소켓 재연결 처리 시작 (백그라운드 복귀)');

    // 타임아웃 설정 (30초)
    _reconnectTimeoutTimer?.cancel();
    _reconnectTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isReconnecting) {
        debugPrint('⏰ 재연결 타임아웃 - 강제 완료');
        _finishReconnect();
      }
    });

    _processReconnection();
  }

  // 🔧 **수정: 재연결 프로세스 - 현재 참가한 방들만 재연결**
  Future<void> _processReconnection() async {
    try {
      final currentRoomIds = <int>[
        ..._joinedRooms,
      ];

      debugPrint('🔄 재연결할 방 목록: $currentRoomIds');

      if (currentRoomIds.isEmpty) {
        _finishReconnect();
        return;
      }

      _pendingReconnectRooms.addAll(currentRoomIds);

      // 🔧 **수정: 재연결 시 join 명령 재전송**
      await _rejoinRooms(currentRoomIds);

      _startRetryFailedRooms();
      _finishReconnect();
    } catch (e) {
      debugPrint('❌ 재연결 프로세스 오류: $e');
      _finishReconnect();
    }
  }

  // 🔧 **추가: 방 재조인 처리**
  Future<void> _rejoinRooms(List<int> roomIds) async {
    for (final roomId in roomIds) {
      try {
        if (_joinedRooms.contains(roomId)) {
          // 소켓에 재조인 명령 전송
          socket.emit('join', roomId);
          _pendingReconnectRooms.remove(roomId);
          debugPrint('✅ 방 재조인 성공: $roomId');

          // 방 간 짧은 대기
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint('❌ 방 재조인 실패 ($roomId): $e');
        _failedRooms.add(roomId);
      }
    }
  }

  // 실패한 방들 재시도
  void _startRetryFailedRooms() {
    if (_failedRooms.isEmpty) return;

    _retryFailedRoomsTimer?.cancel();
    _retryFailedRoomsTimer = Timer(const Duration(seconds: 10), () async {
      if (_failedRooms.isNotEmpty) {
        debugPrint('🔄 실패한 방들 재시도: $_failedRooms');
        final failedRoomsList = _failedRooms.toList();
        _failedRooms.clear();

        for (final roomId in failedRoomsList) {
          await _joinRoomSafely(roomId);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    });
  }

  // 재연결 완료
  void _finishReconnect() {
    _reconnectTimeoutTimer?.cancel();
    _isReconnecting = false;
    _pendingReconnectRooms.clear();
    notifyListeners();
    debugPrint('✅ 소켓 재연결 처리 완료');
  }

  // 특정 방 조인 (Public)
  Future<void> joinRoom(int roomId) async {
    try {
      await _joinRoom(roomId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 방 조인 오류 ($roomId): $e');
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
      debugPrint('❌ 방 데이터 새로고침 오류 ($roomId): $e');
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
      debugPrint('❌ 읽음 상태 업데이트 오류: $e');
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
      debugPrint('❌ 이전 채팅 로드 오류: $e');
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
      debugPrint('❌ 이후 채팅 로드 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }

    return false;
  }

  // 방 나가기
  Future<void> removeRoom(int roomId) async {
    try {
      socket.emit('leave', {'roomId': roomId});
      _cleanupRoomData(roomId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 방 나가기 오류: $e');
    }
  }

  // 유틸리티 메서드들
  bool isJoined(int roomId) =>
      _joinedRooms.contains(roomId) &&
          !_pendingReconnectRooms.contains(roomId) &&
          !_failedRooms.contains(roomId);

  // 데이터 준비 상태 확인
  bool isRoomDataReady(int roomId) {
    return _my[roomId] != null &&
        _chat[roomId] != null &&
        _joinedRooms.contains(roomId) &&
        !_pendingReconnectRooms.contains(roomId) &&
        !_failedRooms.contains(roomId);
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
      debugPrint('❌ 배지 업데이트 오류: $e');
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
    _pendingReconnectRooms.clear();
    _failedRooms.clear();
    _isReconnecting = false;
    _socketListenersRegistered = false;
    _reconnectTimeoutTimer?.cancel();
    _retryFailedRoomsTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimeoutTimer?.cancel();
    _retryFailedRoomsTimer?.cancel();
    _lastReadUpdateTimer?.cancel();
    _socketListenersRegistered = false;
    super.dispose();
  }
}