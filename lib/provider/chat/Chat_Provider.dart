import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

class ChatProvider extends ChangeNotifier{
  final SocketManager socket = SocketManager();

  final Set<int> _joinedRooms = {};
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};
  final Map<int, int?> _lastReadChatId = {}; // 각 방의 lastRead 저장
  final Map<int, Set<int>> _loadedChatIds = {}; // 중복 방지를 위한 로드된 채팅 ID 관리

  Map<int, List<Chat>> get chat => _chat;
  Map<int, Map<String, dynamic>> get my => _my;

  void myMemberUpdate({required int roomId, required String field, required dynamic data}){
    _my[roomId]![field] = data;
    notifyListeners();
  }

  void initializeSocket() async{
    await socket.connect();
  }

  bool _socketLoading = false;
  bool get socketLoading => _socketLoading;

  void onDisconnect(){
    _joinedRooms.clear();
    notifyListeners();
  }

  Future initChatProvider() async{
    final rooms = AppRoute.context?.read<RoomsProvider>().rooms;

    if (rooms == null) return;
    for (final roomId in rooms.keys) {
      await joinRoom(roomId);
    }
  }

  Future<void> joinRoom(int roomId) async{
    if (_joinedRooms.contains(roomId)) return;
    await setChats(roomId);
    await setMyRoom(roomId);
    socket.emit('join', roomId);
    _joinedRooms.add(roomId);
    notifyListeners();
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

  // ✅ 수정된 코드 (한 줄)
  Chat? latestChatTime(int roomId) =>
      (_chat[roomId]?.isNotEmpty == true)
          ? _chat[roomId]!.reduce((a, b) => a.createAt.isAfter(b.createAt) ? a : b)
          : null;


  // lastRead 채팅 ID 반환
  int? getLastReadChatId(int roomId) => _lastReadChatId[roomId];

  void setSocketListeners(){
    socket.on("error", (data)=> DialogManager.errorHandler(data['error']));
    socket.on("chat", _chatHandler);
    socket.on("removeChat", _removeChatHandler);
    socket.on("kicked", _kickedHandler);
  }

  void _kickedHandler(dynamic data) {
    try {
      print('🔥 kicked 이벤트 수신: $data');

      // ✅ 1. 데이터 검증
      if (data == null) {
        print('❌ kicked 데이터가 null입니다');
        return;
      }

      final roomId = data['roomId'];
      final room = data['room'];

      if (roomId == null) {
        print('❌ roomId가 null입니다');
        return;
      }

      print('✅ 방 $roomId에서 추방 처리 시작');

      // ✅ 2. 안전한 데이터 제거
      _chat.remove(roomId);
      _my.remove(roomId);
      _lastReadChatId.remove(roomId);

      // ✅ 3. 안전한 라우터 접근
      final context = AppRoute.context;
      if (context == null) {
        print('❌ AppRoute.context가 null입니다');
        notifyListeners();
        return;
      }

      // ✅ 4. 안전한 현재 경로 확인
      final router = GoRouter.of(context);
      final state = router.state;

      bool isInKickedRoom = false;
      try {
        if (state.path == '/room/:roomId' &&
            state.pathParameters['roomId'] == roomId.toString()) {
          isInKickedRoom = true;
        }
      } catch (e) {
        print('❌ 라우터 상태 확인 오류: $e');
      }

      // ✅ 5. 안전한 네비게이션 (다음 프레임에서 실행)
      if (isInKickedRoom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            try {
              context.go('/my');
              print('✅ 메인 페이지로 이동');
            } catch (e) {
              print('❌ 네비게이션 오류: $e');
            }
          }
        });
      }

      // ✅ 6. 안전한 다이얼로그 표시 (다음 프레임에서)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showKickedDialog(room);
        }
      });

      // ✅ 7. 안전한 방 목록 새로고침
      _refreshRoomsData(context);

      // ✅ 8. 상태 변경 알림
      notifyListeners();

      print('✅ 추방 처리 완료');

    } catch (e, stackTrace) {
      print('❌ _kickedHandler 오류: $e');
      print('📍 스택 트레이스: $stackTrace');

      // 에러 발생해도 기본적인 정리는 수행
      notifyListeners();
    }
  }

  void _showKickedDialog(Map<String, dynamic>? room) {
    try {
      final roomName = room?['roomName']?.toString() ?? '알 수 없는 방';
      final local = room?['local']?.toString() ?? '알 수 없는 지역';

      DialogManager.showBasicDialog(
        title: '방에서 추방되었습니다',
        content: '$local 지역의 "$roomName" 채팅방에서\n추방되었어요. 다음에 더 좋은 인연으로 만나요!',
        confirmText: '확인',
        onConfirm: () {
          print('✅ 추방 안내 확인됨');
        },
      );
    } catch (e) {
      print('❌ 추방 다이얼로그 오류: $e');

      // 폴백 다이얼로그
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
            roomsProvider.roomInitialize();
            print('✅ 방 목록 새로고침 시작');
          } catch (e) {
            print('❌ 방 목록 새로고침 오류: $e');
          }
        }
      });
    } catch (e) {
      print('❌ _refreshRoomsData 오류: $e');
    }
  }


  _removeChatHandler(data){
    final roomId = data['roomId'];
    final chatId = data['chatId'];
    final index = _chat[roomId]!.indexWhere((e)=> e.chatId == chatId);
    if (index != -1) {
      _chat[roomId]![index].type = ChatType.removed;
      notifyListeners();
    }
  }

  void _chatHandler(dynamic data){
    final Chat chat = Chat.fromJson(json: data);
    final int roomId = chat.roomId;

    // 중복 방지 체크
    _loadedChatIds.putIfAbsent(roomId, () => <int>{});
    if (_loadedChatIds[roomId]!.contains(chat.chatId)) {
      return; // 이미 존재하는 채팅이면 무시
    }

    _chat.putIfAbsent(roomId, () => <Chat>[]).add(chat);
    _loadedChatIds[roomId]!.add(chat.chatId);

    final state = AppRoute.context != null ? GoRouter.of(AppRoute.context!).state : null;

    if(state?.path != null && state!.uri.toString().contains('/room/$roomId')){
      updateMyLastReadInServer(roomId);
    }else{
      _my[roomId]?['unreadCount']++;
      setBadge();
    }

    notifyListeners();
  }

  Future<void> updateMyLastReadInServer(int roomId) async{
    try {
      final lr = chat[roomId]?.lastOrNull?.chatId;
      print(lr);
      if(lr != null){
        await serverManager.put('roomMember/lastread/$roomId?lastRead=$lr');

        // 로컬 lastRead도 업데이트
        if (_my[roomId] != null) {
          _my[roomId]!['lastRead'] = lr;
          _lastReadChatId[roomId] = lr;
        }
      }
    } catch (e) {
      print('lastRead 업데이트 오류: $e');
    }
  }

  // 초기 채팅 로드 (읽은/안읽은 채팅 포함)
  Future<bool> setChats(int roomId) async{
    if(!_socketLoading){
      _socketLoading = true;
      notifyListeners();
    }

    try {
      final response = await serverManager.get('chat/chat?roomId=$roomId');

      if (response.statusCode == 200) {
        final chatsData = response.data['chats'] as List;
        final lastReadChatId = response.data['lastReadChatId'] as int?;
        final unreadCount = response.data['unreadCount'] as int?;
        _lastReadChatId[roomId] = lastReadChatId;

        final newChats = List<Chat>.from(
            chatsData.map((e) => Chat.fromJson(json: e)).toList()
        );

        _chat[roomId] = newChats;

        // 로드된 채팅 ID 추적
        _loadedChatIds[roomId] = newChats.map((chat) => chat.chatId).toSet();
        _my[roomId]!['unreadCount'] = unreadCount;
        notifyListeners();
        return newChats.isNotEmpty;
      }
    } catch (e) {
      print('채팅 로드 오류: $e');
    } finally {
      if(_socketLoading) {
        _socketLoading = false;
        notifyListeners();
      }
    }

    return false;
  }

  // 이전 채팅 로드 (위로 스크롤) - 중복 방지 강화
  Future<bool> loadChatsBefore(int roomId) async {
    if (_socketLoading) return false;

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) return false;

    final oldestChatId = currentChats.first.chatId;

    try {
      _socketLoading = true;
      notifyListeners();

      final response = await serverManager.get('chat/chatsBefore?roomId=$roomId&lastChatId=$oldestChatId');

      if (response.statusCode == 200) {
        final chatsData = response.data as List;
        final newChats = List<Chat>.from(
            chatsData.map((e) => Chat.fromJson(json: e)).toList()
        );

        if (newChats.isNotEmpty) {
          // 중복 체크 후 추가
          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          if (filteredChats.isNotEmpty) {
            // 기존 채팅 앞에 추가
            _chat[roomId]!.insertAll(0, filteredChats);

            // 로드된 ID 추가
            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }

            notifyListeners();
            return chatsData.length >= 20; // 서버에서 받은 원본 데이터 기준으로 판단
          }
        }
      }
    } catch (e) {
      print('이전 채팅 로드 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }

    return false;
  }

  // 이후 채팅 로드 (아래로 스크롤) - 중복 방지 강화
  Future<bool> loadChatsAfter(int roomId) async {
    if (_socketLoading) return false;

    final currentChats = _chat[roomId];
    if (currentChats == null || currentChats.isEmpty) return false;

    final newestChatId = currentChats.last.chatId;

    try {
      _socketLoading = true;
      notifyListeners();

      final response = await serverManager.get('chat/chatsAfter?roomId=$roomId&lastChatId=$newestChatId');

      if (response.statusCode == 200) {
        final chatsData = response.data as List;
        final newChats = List<Chat>.from(
            chatsData.map((e) => Chat.fromJson(json: e)).toList()
        );

        if (newChats.isNotEmpty) {
          // 중복 체크 후 추가
          _loadedChatIds.putIfAbsent(roomId, () => <int>{});
          final filteredChats = newChats.where((chat) =>
          !_loadedChatIds[roomId]!.contains(chat.chatId)
          ).toList();

          if (filteredChats.isNotEmpty) {
            // 기존 채팅 뒤에 추가
            _chat[roomId]!.addAll(filteredChats);

            // 로드된 ID 추가
            for (final chat in filteredChats) {
              _loadedChatIds[roomId]!.add(chat.chatId);
            }

            notifyListeners();
            return chatsData.length >= 20; // 서버에서 받은 원본 데이터 기준으로 판단
          }
        }
      }
    } catch (e) {
      print('이후 채팅 로드 오류: $e');
    } finally {
      _socketLoading = false;
      notifyListeners();
    }

    return false;
  }

  Future<void> setMyRoom(int roomId) async{
    try {
      final myData = await serverManager.get('roomMember/my/$roomId');

      if(myData.statusCode == 200) {
        final data = myData.data;
        _my[roomId] = data;

        // lastRead 동기화
        if (data['lastRead'] != null) {
          _lastReadChatId[roomId] = data['lastRead'];
        }

        notifyListeners();
      }
    } catch (e) {
      print('내 방 정보 로드 오류: $e');
    }
  }

  Future<void> enterRoomUpdateLastRead(int roomId) async {
    if (_my[roomId] != null) {
      final latestChatId = chat[roomId]?.lastOrNull?.chatId ?? 0;
      _my[roomId]!['lastRead'] = latestChatId;
      _my[roomId]!['unreadCount'] = 0;
      _lastReadChatId[roomId] = latestChatId;
      notifyListeners();
    }
  }

  void onReconnect() async{
    final rooms = AppRoute.context?.read<RoomsProvider>().rooms;

    if (rooms == null) return;

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

  Future<void> onReconnectChat(int roomId) async{
    try {
      final lastChatId = _my[roomId]!['lastRead'];
      print('마지막으로 읽은 챗아이디 ${lastChatId}');
      final response = await serverManager.get('chat/reconnect?roomId=$roomId&lastChatId=$lastChatId');

      if (response.statusCode == 200) {
        final data = response.data;
        final chatsData = data['data'] as List;
        final unreadCount = data['unreadCount'];
        final newChats = List<Chat>.from(chatsData.map((e) => Chat.fromJson(json: e)));

        _loadedChatIds.putIfAbsent(roomId, () => <int>{});
        _chat[roomId] ??= [];
        _my[roomId]?['unreadCount'] = unreadCount;

        for (Chat chat in newChats) {
          if (!_loadedChatIds[roomId]!.contains(chat.chatId)) {
            _chat[roomId]!.add(chat);
            _loadedChatIds[roomId]!.add(chat.chatId);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      print('채팅 재연결 오류 (roomId: $roomId): $e');
    }
  }

  Future<void> removeRoom(int roomId) async{
    _joinedRooms.remove(roomId);
    leaveRoom(roomId);
    _chat.remove(roomId);
    _my.remove(roomId);
    _lastReadChatId.remove(roomId);
    _loadedChatIds.remove(roomId);

    try {
      await AppRoute.context!.read<RoomsProvider>().roomInitialize();
    } catch (e) {
      print('방 목록 초기화 오류: $e');
    }
  }

  void changedMyGrade(int roomId, int grade){
    if (_my[roomId] != null) {
      _my[roomId]!['grade'] = grade;
      notifyListeners();
    }
  }

  // 백그라운드에서 복귀 시 데이터 새로고침을 위한 메서드
  Future<void> refreshRoomFromBackground(int roomId) async {
    try {
      // 이미 조인되어 있으면 재연결만, 아니면 새로 조인
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

  void readReset(int roomId){
    if(my[roomId] != null){
      my[roomId]!['unreadCount'] = 0;
    }
    setBadge();
  }

  void setBadge(){
    final badge = my.entries.fold<int>(
        0,(sum, entry) => sum + (entry.value['unreadCount'] as int? ?? 0)
    );
    AppBadgePlus.updateBadge(badge);
  }
}