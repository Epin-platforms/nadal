import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class ScheduleProvider extends ChangeNotifier{
  final _auth = FirebaseAuth.instance;
  late int _scheduleId;

  ScheduleProvider(int scheduleId){
    _scheduleId = scheduleId;
    _fetchSchedule();
  }


  Map? _schedule;
  Map? get schedule => _schedule;

  Map<String, dynamic>? _scheduleMembers;
  Map<String, dynamic>? get scheduleMembers => _scheduleMembers;

  Map<String, List<dynamic>>? teams;

  Map<String, List<dynamic>>? getTeams(){
    if (_scheduleMembers == null)return null;

    final Map<String, List<dynamic>> teamMap = {};

    _scheduleMembers!.forEach((uid, memberData) {
      final String? teamName = memberData['teamName'];

      if (teamName != null && teamName.isNotEmpty) {
        // 팀이 맵에 없으면 빈 배열로 초기화
        if (!teamMap.containsKey(teamName)) {
          teamMap[teamName] = [];
        }

        // 멤버 데이터를 해당 팀 배열에 추가
        teamMap[teamName]!.add(memberData);
      }
    });

    return teamMap;
  }

  _fetchSchedule() async{
     final res = await serverManager.get('schedule/$_scheduleId');

     if(res.statusCode == 200){
       _schedule = res.data['schedule'];

       if(_schedule == null){
         AppRoute.context?.pop();
         AppRoute.context?.read<UserProvider>().fetchMySchedules(DateTime.now(), force: true, reFetch: true);
         DialogManager.showBasicDialog(title: '어라..?', content: "해당 스케줄을 찾을수 없어요", confirmText: "확인");
       }

       final members = List.from(res.data['members'] ?? []);

       _scheduleMembers = {
         for (final member in members)
           member['uid']: member
       };

       if(_schedule!['roomId'] != null && //만약 룸아이디가 있고
           !_scheduleMembers!.keys.contains(_auth.currentUser!.uid) && //참가중이 아니고
             AppRoute.context!.read<RoomsProvider>().rooms!.keys.contains(_schedule!['roomId']!) //내가 참가중인 방이 아니라면
           ){
          AppRoute.context?.pushReplacement('room/preview/${_schedule!['roomId']}'); //해당 방 가입페이지로 이동
       }
     }

     if(_schedule!['isKDK'] == 0 && _schedule!['isSingle'] == 0){ //만약 토너먼트 복식이라면
       teams = getTeams();
     }

     notifyListeners();
  }

  //멤버만 업데이트
  Future<void> get updateMembers => _updateMembers();

  Future<void> _updateMembers() async {
    try {
      final scheduleId = schedule?['scheduleId'];
      final useNickname = schedule?['useNickname'] ?? 1;

      if (scheduleId == null) {
        print('스케줄 정보가 없습니다');
        return;
      }

      final res = await serverManager.get('scheduleMember/$scheduleId?useNickname=$useNickname');

      if (res.statusCode == 200 && res.data is List) {
        final members = List<Map<String, dynamic>>.from(res.data);
        _scheduleMembers = {
          for (final member in members)
            if (member['uid'] != null) member['uid']: member,
        };

        if(_schedule?['isKDK'] == 0 && _schedule?['isSingle'] == 0){
          teams = getTeams();
        }

        notifyListeners();
      } else {
        print('멤버 데이터를 불러오지 못했습니다: ${res.statusCode}');
      }

    } catch (e, st) {
      print('멤버 업데이트 중 오류 발생: $e');
      print(st);
    }
  }


  //참가하기
  Future participateSchedule() async{
    //1차 거르기
    final check = _checkCanParticipate();

    if(check.isNotEmpty){
      return check;
    }

    AppRoute.pushLoading();
      final Map item = {
        'scheduleId' : schedule!['scheduleId'],
        'gender' : AppRoute.context?.read<UserProvider>().user?['gender']
      };

      await serverManager.post('schedule/participation', data: item);

      AppRoute.popLoading();
      return 'complete';
  }

  //참가 거르기
  String _checkCanParticipate(){
    String result = '';

    final gender = AppRoute.context?.read<UserProvider>().user?['gender'];

    if(schedule!['maleLimit'] != null && gender == 'M'){
      final limit = schedule!['maleLimit'];
      final maleMemberCount = scheduleMembers!.values.where((e)=> e['gender'] == 'M').length;

      if(limit <= maleMemberCount){
        DialogManager.errorHandler('남자 인원이 다찼어요.');
        return 'maleLimit';
      }
    }else if(schedule!['femaleLimit'] != null && gender == 'F'){
      final limit = schedule!['femaleLimit'];
      final femaleMemberCount = scheduleMembers!.values.where((e)=> e['gender'] == 'F').length;

      if(limit <= femaleMemberCount){
        DialogManager.errorHandler('여자 인원이 다찼어요.');
        return 'femaleLimit';
      }
    }

    //게임 최대 인원 판단
    if(schedule!['isKDK'] == true && schedule!['isSingle'] == true){
      final limit = scheduleMembers!.length; //최대 13명 가능
      if(limit >= 13){
        DialogManager.errorHandler('게임 인원이 다찼어요.');
        return 'playerLimit';
      }
    }else if(schedule!['isKDK'] == true && schedule!['isSingle'] == false){
      final limit = scheduleMembers!.length; //최대 16명 가능
      if(limit >= 16){
        DialogManager.errorHandler('게임 인원이 다찼어요.');
        return 'playerLimit';
      }
    }

    return result;
  }

  //팀 참가하기
  Future participateTeamSchedule(int teamId) async{
    AppRoute.pushLoading();
    try{
      final Map item = {
        'scheduleId' : schedule!['scheduleId'],
        'teamId' : teamId
      };
      final res = await serverManager.post('schedule/participation/team', data: item);

      if(res.statusCode == 204){
        return 'exist';
      }

      return 'complete';
    }finally{
      AppRoute.popLoading();
    }
  }


  ///참가 거절
  memberParticipation(Map user, bool approval) async{
    final data = {
      'uid' : user['uid'],
      'scheduleId' : schedule?['scheduleId'],
      'approval' : approval,
      'gender' : user['gender']
    };

    final res =  await serverManager.put('scheduleMember/updateApproval', data: data);

    if(res.statusCode == 200){
      updateMembers;
    }
  }


  //참가 취소
  Future<void> cancelParticipation() async {
    AppRoute.pushLoading();

    final res = await serverManager.delete('schedule/participationCancel/${schedule!['scheduleId']}');

    AppRoute.popLoading();
    if (res.statusCode == 200) {
      _scheduleMembers!.remove(_auth.currentUser!.uid); // 🔑 로컬 상태에서 제거
      AppRoute.context?.read<UserProvider>().removeScheduleById(schedule!['scheduleId']);
      notifyListeners();
    }
  }

  Future<void> cancelTeamParticipation() async {
    AppRoute.pushLoading();
    final res = await serverManager.delete('schedule/participationCancel/team/${schedule!['scheduleId']}');

    AppRoute.popLoading();
    if (res.statusCode == 200) {
      updateMembers;
      notifyListeners();
    }
  }

  //스케줄 삭제
  Future<void> deleteSchedule() async{
    AppRoute.pushLoading();
    final res = await serverManager.delete('schedule/$_scheduleId');

    AppRoute.popLoading();

    if(res.statusCode == 200){
      AppRoute.context?.read<UserProvider>().removeScheduleById(_scheduleId); //삭제시 일정 제거
      AppRoute.context?.pop();
      DialogManager.showBasicDialog(title: '스케줄 삭제 완료!', content: "선택하신 스케줄을 깔끔하게 정리했어요.", confirmText: "확인");
    }
  }

  //게임프로바이더에서 참조할 함수
  changeState(int state){
    schedule!['state'] = state;
    notifyListeners();
  }


}