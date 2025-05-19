import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/manager/server/Socket_Manager.dart';

class GameProvider extends ChangeNotifier{
  late ScheduleProvider scheduleProvider;
  final SocketManager socket = SocketManager();
  bool _create = false; //사용안되면 init안되게 방지하는 변수 + 여러번 빌드 안되게 방지

  //자주사용되는 스케줄 ID는 변수로저장
  late final int _scheduleId;


  late bool isTeamGame;
  initGameProvider(ScheduleProvider scheduleProvider){
    if(_create) return;

    this.scheduleProvider = scheduleProvider;

    if(scheduleProvider.schedule?['state'] != null){ //게임인경우
      //게임프로바이더가 만들어졌는지 확인 및 스케줄 아이디 적용
      _create = true;
      _scheduleId = scheduleProvider.schedule!['scheduleId'];
      //현재게임이 팀게임인지 판단
      isTeamGame = (scheduleProvider.schedule!['isKDK'] == false && scheduleProvider.schedule!['isSingle'] == false) ? true : false;
      //현재 뷰 적용
      _currentSateView = scheduleProvider.schedule!['state'];

      //소켓 접속
      //실시간 게임 소켓 리스너 달기
      if(scheduleProvider.schedule!['state'] < 4){
        _gameSocketLister(on: true);
        joinedGame();
      }
    }
  }

  int get currentStateView => _currentSateView;

  setViewPage(int page){
      if(_currentSateView != page){
        _currentSateView = page;
        notifyListeners();
    }
  }

  late int _currentSateView;

  void joinedGame(){
    socket.emit('joinGame', scheduleProvider.schedule!['scheduleId']);
  }

  @override
  void dispose(){
    _gameSocketLister(on: false);
    socket.emit('leaveGame',  scheduleProvider.schedule!['scheduleId']);
    super.dispose();
  }


  _gameSocketLister({required bool on}){
    if(on){
      socket.on('changedState',_changedStateHandler);
      socket.on('refreshMember', _refreshMemberHandler);
      socket.on('score', _changedScore);
      socket.on('court', _changedCourt);
      socket.on('refreshGame', _refreshGame);
    }else{
      socket.off('changedState', _changedStateHandler);
      socket.off('refreshMember', _refreshMemberHandler);
      socket.off('score', _changedScore);
      socket.off('court', _changedCourt);
      socket.off('refreshGame', _refreshGame);
    }
  }

  //리스너 핸들어
  //사용자 다시불러오기
  void _refreshMemberHandler(dynamic data) {
    scheduleProvider.updateMembers;
  }

  //게임테이블 다시불러오기
  void _refreshGame(dynamic data){
    fetchTables();
  }

  void _changedStateHandler(dynamic data){
    scheduleProvider.changeState(data['state']);
    _currentSateView = data['state'];
    notifyListeners();
  }

  void _changedScore(dynamic data){
    _tables![data['tableId']]!['score${data['where']}'] = data['score'];
    notifyListeners();
  }

  void _changedCourt(dynamic data){
    _tables![data['tableId']]!['court'] = data['court'];
    notifyListeners();
  }


  //게임 직접적인 관련 함수
  //보통 1 --> 0 으로갈때만 사용
  changeState(int state) async{
    //게임 상태변화
    AppRoute.pushLoading();
    await serverManager.put('game/state', data: {"scheduleId" : _scheduleId, "state" : state}); //상태 업데이트 연결
    AppRoute.popLoading();
  }


  //게임시작
  startGame() async{
    AppRoute.pushLoading();
    //거절 사용자 정리 --> 사용자에게 인덱스 적용
    await serverManager.put('game/start/$_scheduleId');
    AppRoute.popLoading();
  }

  updateMemberIndex(List members) async{
    AppRoute.pushLoading();
    Map data = {
      'scheduleId' : _scheduleId
    };

    for(int i = 0 ; i < members.length; i++){
      final member = members[i];
      data.addAll({
        member['uid'] : (i+1)
      });
    }

    final res = await serverManager.put('game/member/indexUpdate', data:  data);
    AppRoute.popLoading();

    return res;
  }

  updateTeamIndex(List teamsList) async {
    AppRoute.pushLoading();

    // 기본 데이터 객체 생성 (scheduleId 포함)
    Map<String, dynamic> data = {
      'scheduleId': _scheduleId
    };

    // 각 팀의 모든 멤버에게 팀의 새 인덱스 적용
    for (int i = 0; i < teamsList.length; i++) {
      final team = teamsList[i];
      if (team['walkOver'] != true) {
        for (var member in team['members']) {
          // 서버가 기대하는 형식: { uid1: index1, uid2: index2, ... }
          final uid = member['uid'];
          if (uid != null) {
            data[uid] = i + 1; // 인덱스는 1부터 시작
          }
        }
      }
    }

    // 서버 요청 전송
    final res = await serverManager.put('game/member/indexUpdate', data: data);
    AppRoute.popLoading();

    return res;
  }

  //게임테이블 생성
  createGameTable() async{
    AppRoute.pushLoading();
    final isSingle = (scheduleProvider.schedule!['isSingle'] == 1);
    final isKDK = (scheduleProvider.schedule!['isKDK'] == 1);
    final route = (isKDK && isSingle) ? 'singleKDK' : (isKDK && !isSingle) ? 'doubleKDK' : (!isKDK && isSingle) ? 'singleTournament' : 'doubleTournament';
    await serverManager.post('game/createTable/$route', data: {'scheduleId' : _scheduleId});
    AppRoute.popLoading();
  }


  //게임 테이블들
  Map<int, Map>? _tables;
  Map<int, Map>? get tables => _tables;

  void fetchTables() async {
    final res = await serverManager.get('game/table/$_scheduleId');

    _tables = {};
    if (res.statusCode == 200) {
      final list = List<Map>.from(res.data);
      _tables = {
        for (final table in list) table['tableId'] as int: table,
      };
    }
    notifyListeners();
  }


  void onChangedScore(int tableId, int score, int where) async{
    final data = {
      'scheduleId' : _scheduleId,
      'tableId' : tableId,
      'score' : score,
      'where' : where //1,2번인지
    };
    await serverManager.put('game/score', data: data);
  }

  void onChangedCourt(int tableId, String court) async{
    final data = {
      'scheduleId' : _scheduleId,
      'tableId' : tableId,
      'court' : court
    };
    await serverManager.put('game/court', data:  data);
  }

  //코트입력
  int? _courtInputTableId;
  int? get courtInputTableId => _courtInputTableId;

  TextEditingController? _courtController;
  TextEditingController? get courtController => _courtController;

  setCourtInputTableId(int? tableId){
     _courtInputTableId = tableId;
     if(tableId == null){
       _courtController = null;
     }else{
       _courtController = TextEditingController(text: _tables![tableId]!['court']);
     }
     notifyListeners();
  }


  //게임 종료
  endGame() async{
    AppRoute.pushLoading();
    final isSingle = (scheduleProvider.schedule!['isSingle'] == 1);
    final isKDK = (scheduleProvider.schedule!['isKDK'] == 1);
    final finalScore = scheduleProvider.schedule!['finalScore'];
    if(isSingle && isKDK){
      await serverManager.post('game/end/singleKDK/$_scheduleId?finalScore=$finalScore');
    }else if(!isSingle && isKDK){
      await serverManager.post('game/end/doubleKDK/$_scheduleId?finalScore=$finalScore');
    }else if(isSingle && !isKDK){
      await serverManager.post('game/end/singleTournament/$_scheduleId?finalScore=$finalScore');
    }else{
      await serverManager.post('game/end/doubleTournament/$_scheduleId?finalScore=$finalScore');
    }
    AppRoute.popLoading();
  }

  //레벨정보
  List? _result;
  List? get result => _result;

  fetchResult() async{
    final res = await serverManager.get('game/result/$_scheduleId');

    if(res.statusCode == 200){
      _result = List.from(res.data);
      notifyListeners();
    }
  }


  final _uid = FirebaseAuth.instance.currentUser!.uid;

  List myGames(){
    return tables!.entries.where((e) =>
    e.value['player1_0'] ==  _uid ||
        e.value['player1_1'] == _uid ||
        e.value['player2_0'] == _uid ||
        e.value['player2_1'] == _uid).toList();
  }

  void nextRound(int currentRound) async{
    AppRoute.pushLoading();
    await serverManager.put('game/nextRound', data: {'scheduleId' : _scheduleId, 'round' : currentRound});
    AppRoute.popLoading();
  }


}