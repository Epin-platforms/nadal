import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

import '../../manager/project/Import_Manager.dart';

class TeamProvider extends ChangeNotifier{
  late int _roomId;
  late int _scheduleId;

  TeamProvider(int roomId, int scheduleId){
    _roomId = roomId;
    _scheduleId = scheduleId;
    fetchMyTeam();
  }

  List<Map>? _members;
  List<Map>? get members => _members;

  String? _selectUser;
  String? get selectUser => _selectUser;

  List<Map>? _teams;
  List<Map>? get teams => _teams;

  fetchMyTeam() async{
    final res = await serverManager.get('user/team?roomId=$_roomId');

    _teams = [];
    if(res.statusCode == 200){
      _teams = List.from(res.data);
    }

    if(res.statusCode == 400 || res.statusCode == 404){
      Navigator.pop(AppRoute.context!);
      DialogManager.showBasicDialog(title: '앗!', content: '알수없는 방 정보에요 다시한번 확인해주세요', confirmText: '확인');
      return;
    }

    notifyListeners();
  }


  //방 패치
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;

  fetchRoomMember() async{
    if(_loading || !_hasMore) return; //로딩일 경우에는 무시
    _loading = true;
    try{
      final res = await serverManager.get('schedule/team/init?roomId=$_roomId&scheduleId=$_scheduleId&offset=$_offset');

      _members = [];
      if(res.statusCode == 200){
        final list =  List.from(res.data);

        if (list.length < 10) {
          _hasMore = false; // 다음 로딩 막기
        }else{
          _offset++;
        }


        for(var item in list){
          if(_members!.where((e)=> e['uid'] == item['uid']).isEmpty){ //이미 정보에없다면
            _members!.add(item);
          }
        }
      }
    }finally{
      _loading = false;
    }
    notifyListeners();
  }

  //사용자 찾기
  List<Map> _result = [];
  List<Map> get result => _result;

  bool _searching = false;
  bool get searching => _searching;

  String _lastValue = '';
  String get lastValue => _lastValue;

  int _resultOffset = 0;
  bool _resultHasMore = true;

  fetchResult(String value) async{
    if(value.isEmpty){
      _resultOffset = 0;
      _hasMore = true;
      _lastValue = '';
      _result.clear();
      notifyListeners();
      return;
    }
    try{
      if(_searching && !_resultHasMore) return;

      _searching = true;
      notifyListeners();

      if(_lastValue != value){
        _resultHasMore = true;
        _resultOffset = 0;
        _lastValue = value;
      }

      final res = await serverManager.get('schedule/team/search?roomId=$_roomId&offset=$_resultOffset&scheduleId=$_scheduleId&query=$value');

      if(res.statusCode == 200){
          final list = List.from(res.data);

          if(list.length < 10){
            _resultHasMore = false;
          }else{
            _resultOffset++;
          }

          for(var item in list){
            if(_result.where((e)=> e['uid'] == item['uid']).isEmpty){ //이미 정보에없다면
              _result.add(item);
            }
          }
      }
    }finally{
      _searching = false;
      notifyListeners();
    }
  }


  //팀원선택
  setSelectUser(String? uid){
    _selectUser = uid;
    notifyListeners();
  }


  //팀만들기
  createTeam(String teamName) async {
    AppRoute.pushLoading();
    final data = {
      'roomId': _roomId,
      'otherUid': _selectUser,
      'teamName': teamName
    };

    int code = 0;
    try {
      final res = await serverManager.post('user/team', data: data);

      code = res.statusCode!;
      if (res.statusCode == 200) {
        fetchMyTeam();
      }
    } catch (e) {
      print(e);
    } finally {
      AppRoute.popLoading();
      _selectUser = null;
      if(code == 203){
        DialogManager.showBasicDialog(
          title: '앗! 이미 팀이에요',
          content: '이 사용자와는 이미 팀이 있어요. 다른 분을 찾아볼까요?',
          confirmText: '다른 사용자 보기',
        );
      }else if(code == 204){
        DialogManager.showBasicDialog(
          title: '팀명이 겹쳤어요',
          content: '조금 더 특별한 이름으로 지어보는 건 어때요?',
          confirmText: '좋아요',
        );
      }
    }
  }

  int? _selectMyTeam;
  int? get selectMyTeam => _selectMyTeam;

  setMyTeam(int? value){
    _selectMyTeam = value;
    notifyListeners();
  }

}