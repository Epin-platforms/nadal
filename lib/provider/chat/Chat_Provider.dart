import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';

class ChatProvider extends ChangeNotifier{
  final SocketManager socket = SocketManager();

  final Set<int> _joinedRooms = {};
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};
  final Map<int, int?> _lastReadChatId = {}; // 각 방의 lastRead 저장

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

  Chat? latestChatTime(int roomId) => _chat[roomId]?.reduce((a, b) => a.createAt.isAfter(b.createAt) ? a : b);

  // lastRead 채팅 ID 반환
  int? getLastReadChatId(int roomId) => _lastReadChatId[roomId];

  void setSocketListeners(){
    socket.on('newLogined', _newLoginedHandler);
    socket.on("error", (data)=> DialogManager.errorHandler(data['error']));
    socket.on("chat", _chatHandler);
    socket.on("removeChat", _removeChatHandler);
    socket.on("kicked", _kickedHandler);
  }

  void _newLoginedHandler(dynamic data) async{
    try {
      // 1. 먼저 다이얼로그로 사용자에게 알림
      await DialogManager.showBasicDialog(
        title: '다른 기기에서 로그인됨',
        content: '다른 기기에서 로그인하여 현재 세션이 종료됩니다.\n잠시 후 로그인 화면으로 이동합니다.',
        confirmText: '확인',
        // 다이얼로그가 닫히지 않도록 설정 (선택사항)
        barrierDismissible: false,
      );

      // 2. 사용자가 확인을 누른 후 로그아웃 처리
      await _handleForcedLogout();

    } catch (e) {
      print('새 로그인 핸들러 오류: $e');
      // 에러가 발생해도 강제 로그아웃 실행
      await _handleForcedLogout();
    }
  }

  Future<void> _handleForcedLogout() async {
    try {
      // 1. 로딩 표시 (선택사항)
      if (AppRoute.context != null) {
        AppRoute.pushLoading();
      }

      // 2. 소켓 연결 해제
      final chatProvider = AppRoute.context?.read<ChatProvider>();
      if (chatProvider != null) {
        chatProvider.onDisconnect();
      }

      // 3. Firebase 로그아웃
      await FirebaseAuth.instance.signOut();

      // 4. 로컬 데이터 정리 (필요시)
      // await _clearLocalData();

      // 5. 로딩 제거
      if (AppRoute.context != null) {
        AppRoute.popLoading();
      }

      // 6. 로그인 페이지로 이동 (모든 스택 제거)
      if (AppRoute.context != null) {
        AppRoute.context!.go('/login?reset=true&reason=newDevice');
      }

    } catch (e) {
      print('강제 로그아웃 처리 오류: $e');

      // 에러가 발생해도 최소한 로그인 페이지로는 이동
      try {
        if (AppRoute.context != null) {
          AppRoute.popLoading(); // 로딩이 있다면 제거
          AppRoute.context!.go('/login?reset=true&error=logout_failed');
        }
      } catch (fallbackError) {
        print('fallback 로그아웃 오류: $fallbackError');
      }
    }
  }

  void _kickedHandler(dynamic data){
    final roomId = data['roomId'];
    final room = data['room'];

    _chat.remove(roomId);
    _my.remove(roomId);
    _lastReadChatId.remove(roomId);

    final state = GoRouter.of(AppRoute.context!).state;

    if(state.path == '/room/:roomId' && state.pathParameters['roomId'] == roomId.toString()){
      AppRoute.context!.go('/my');
    }

    DialogManager.showBasicDialog(
      title: '방에서 추방되었습니다',
      content: '${room['local']} 지역의 "${room['roomName']}" 채팅방에서\n추방되었어요. 다음에 더 좋은 인연으로 만나요!',
      confirmText: '확인',
    );

    AppRoute.context!.read<RoomsProvider>().roomInitialize();
    notifyListeners();
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

    if(_chat.containsKey(roomId)){
      final chats = _chat[roomId]!;

      if(chats.where((e)=>e.chatId == chat.chatId).isNotEmpty){
        return;
      }
    }

    _chat.putIfAbsent(roomId, () => <Chat>[]).add(chat);

    final state = AppRoute.context != null ? GoRouter.of(AppRoute.context!).state : null;

    if(state?.path != null && state!.uri.toString().contains('/room/$roomId')){
      updateMyLastReadInServer(roomId, chat.chatId);
    }else{
      _my[roomId]?['unreadCount']++;
    }

    notifyListeners();
  }

  Future<bool> updateMyLastReadInServer(int roomId, int? lastRead) async{
    try {
      final lr = lastRead ?? chat[roomId]?.lastOrNull?.chatId;
      if(lr != null){
        await serverManager.put('roomMember/lastread/$roomId?lastRead=$lr');
        return true;
      }
      return false;
    } catch (e) {
      print('lastRead 업데이트 오류: $e');
      return false;
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

        _lastReadChatId[roomId] = lastReadChatId;

        final newChats = List<Chat>.from(
            chatsData.map((e) => Chat.fromJson(json: e)).toList()
        );

        _chat[roomId] = newChats;
        notifyListeners();

        // 더 안전한 로직:
        // 1. 채팅이 하나도 없으면 더 로드할 것 없음
        // 2. 채팅이 있으면 일단 더 로드 시도해볼 수 있음 (실제 요청 시 빈 배열이 오면 그때 false로 처리)
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

  // 이전 채팅 로드 (위로 스크롤)
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
        final newChats = List<Chat>.from(
            response.data.map((e) => Chat.fromJson(json: e)).toList()
        );

        if (newChats.isNotEmpty) {
          // 기존 채팅 앞에 추가
          _chat[roomId]!.insertAll(0, newChats);
          notifyListeners();
          return newChats.length >= 20;
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

  // 이후 채팅 로드 (아래로 스크롤)
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
        final newChats = List<Chat>.from(
            response.data.map((e) => Chat.fromJson(json: e)).toList()
        );

        if (newChats.isNotEmpty) {
          // 기존 채팅 뒤에 추가
          _chat[roomId]!.addAll(newChats);
          notifyListeners();
          return newChats.length >= 20;
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
        _my[roomId] = myData.data;
        notifyListeners();
      }
    } catch (e) {
      print('내 방 정보 로드 오류: $e');
    }
  }

  Future<void> enterRoomUpdateLastRead(int roomId) async {
    if (_my[roomId] != null) {
      _my[roomId]!['lastRead'] = chat[roomId]?.lastOrNull?.chatId ?? 0;
      _my[roomId]!['unreadCount'] = 0;
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
      final lastChatId = _chat[roomId]?.lastOrNull?.chatId;
      final response = await serverManager.get('chat/reconnect?roomId=$roomId&lastChatId=$lastChatId');

      if (response.statusCode == 200) {
        final newChats = List<Chat>.from(response.data.map((e) => Chat.fromJson(json: e)));

        final existingIds = _chat[roomId]?.map((e) => e.chatId).toSet() ?? <int>{};

        _chat[roomId] ??= [];

        for (Chat chat in newChats) {
          if (!existingIds.contains(chat.chatId)) {
            _chat[roomId]!.add(chat);
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
}