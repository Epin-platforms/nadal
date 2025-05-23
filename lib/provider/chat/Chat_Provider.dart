
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Socket_Manager.dart';


class ChatProvider extends ChangeNotifier{
  final SocketManager socket = SocketManager();

  //방 소켓 관리
  final Set<int> _joinedRooms = {};
  final Map<int, List<Chat>> _chat = {};
  final Map<int, Map<String, dynamic>> _my = {};

  Map<int, List<Chat>> get chat => _chat;
  Map<int, Map<String, dynamic>> get my => _my;

  void myMemberUpdate({required int roomId, required String field, required dynamic data}){
    _my[roomId]![field] = data;
    notifyListeners();
  }

  //소켓 연결
  void initializeSocket() async{
    await socket.connect();
  }

  //채팅 프로바이더로 사용자 채팅방 내 채팅정보 + 내 정보 다시불러오기
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
        // roomId 그대로 보내거나, toString() 해도 무방
        await joinRoom(roomId);
      }
  }

  Future<void> joinRoom(int roomId) async{
    if (_joinedRooms.contains(roomId)) return;
    await setChats(roomId);
    await setMyRoom(roomId);
    //조인하기
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


  //초기 리스너 등록
  setSocketListeners(){
    socket.on("error", (data)=> DialogManager.errorHandler(data['error']));
    socket.on("chat", _chatHandler); //채팅이 옴
    socket.on("removeChat", _removeChatHandler);
    socket.on("kicked", _kickedHandler);
  }

  _kickedHandler(dynamic data){
    final roomId = data['roomId'];
    final room = data['room'];
    //방에서 정보 삭제
    _chat.remove(roomId);
    _my.remove(roomId);

    //만약 페이지에있다면 내보내기
    final  state = GoRouter.of(AppRoute.context!).state;

    if(state.path == '/room/:roomId' && state.pathParameters['roomId'] == roomId){
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
    _chat[roomId]![index].type = ChatType.removed;
    notifyListeners();
  }

  _chatHandler(data){
     print(data);
     final Chat chat = Chat.fromJson(json: data);
     final int roomId = chat.roomId;

     if(_chat.containsKey(roomId)){ //이미 존재하는거라면
       final chats = _chat[roomId]!;

       if(chats.where((e)=>e.chatId == chat.chatId).isNotEmpty){ //이미 챗아이디가 존재한다면
         return;
       }
     }

     //없다면 업데이트
      _chat.putIfAbsent(roomId, () => <Chat>[]).add(chat);

     final state = AppRoute.context != null ? GoRouter.of(AppRoute.context!).state : null;

     //방에 들어와있다면 lastRead를 업데이트
     if(state?.path != null && state!.path!.contains('room/:roomId')){
       final roomId = int.tryParse(state.pathParameters['roomId'] ?? '');

       if(roomId != null){
         updateMyLastReadInServer(roomId);
       }
     }else{ //안들어와있다면 안읽은 메시지 업데이트
       _my[roomId]?['unreadCount']++;
     }

     notifyListeners();
  }


  updateMyLastReadInServer(int roomId) async{
    await serverManager.put('roomMember/lastread/$roomId');
  }

  Future<bool> setChats(int roomId) async{
    if(!_socketLoading){
      _socketLoading = true;
      notifyListeners();
    }

    final lastChatId = chat[roomId]?.firstOrNull?.chatId;

    final query = lastChatId != null
        ? 'chat/chat?roomId=$roomId&lastChatId=$lastChatId'
        : 'chat/chat?roomId=$roomId';

    final chatsData = await serverManager.get(query);

    if (chatsData.statusCode == 200) {
      final newChats = List<Chat>.from(
          chatsData.data.map((e) => Chat.fromJson(json: e)).toList()
      );

      if (newChats.isNotEmpty) {
        _chat[roomId] ??= [];

        // 최신순 정렬된 데이터를 뒤집어서 과거순으로 추가
        for (var chat in newChats.reversed) {
          if (_chat[roomId]!.every((e) => e.chatId != chat.chatId)) {
            _chat[roomId]!.insert(0, chat); // prepend
          }
        }

        return newChats.length >= 20; // 또는 서버에서 쿼리의 LIMIT 값
      }
    }

    if(_socketLoading) _socketLoading = false;
    notifyListeners();

    return false;
  }

  Future<void> setMyRoom(int roomId) async{
    final myData = await serverManager.get('roomMember/my/$roomId');

    if(myData.statusCode == 200) {
      _my[roomId] = myData.data;
      notifyListeners();
    }
  }


  enterRoomUpdateLastRead(int roomId){
    _my[roomId]?['lastRead'] = DateTime.now().toLocal().toIso8601String();
    _my[roomId]?['unreadCount'] = 0;
    notifyListeners();
  }

  void onReconnect() async{
    final rooms = AppRoute.context?.read<RoomsProvider>().rooms;

    if (rooms == null) return;
    for (final roomId in rooms.keys) {
        if (_joinedRooms.contains(roomId)) return;
        await onReconnectChat(roomId);
        await setMyRoom(roomId);
        //조인하기
        socket.emit('join', roomId);
        _joinedRooms.add(roomId);
        notifyListeners();
    }
  }

  Future<void> onReconnectChat(int roomId) async{
    final lastChatId = _chat[roomId]?.last.chatId;
    final response = await serverManager.get('chat/reconnect?roomId=$roomId&lastChatId=$lastChatId');
    if (response.statusCode == 200) {
      final newChats = List<Chat>.from(response.data.map((e) => Chat.fromJson(json: e)));

      // ✅ 이미 존재하는 chatId를 Set으로 추출 (O(1) lookup)
      final existingIds = _chat[roomId]?.map((e) => e.chatId).toSet() ?? <int>{};

      for (Chat chat in newChats) {
        if (!existingIds.contains(chat.chatId)) {
          _chat[roomId]?.add(chat);
        }
      }

      notifyListeners();
    }
  }

  //방 정보 제거 (나가기, 추방, 방삭제)
  Future<void> removeRoom(int roomId) async{
    _joinedRooms.remove(roomId);
    leaveRoom(roomId);
    _chat.remove(roomId);
    _my.remove(roomId);
    await AppRoute.context!.read<RoomsProvider>().roomInitialize();
  }

  changedMyGrade(int roomId, int grade){
    _my[roomId]!['grade'] = grade;
    notifyListeners();
  }
}