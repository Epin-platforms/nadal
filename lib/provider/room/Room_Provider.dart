import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/room/Room_Log.dart';

import '../../manager/server/Socket_Manager.dart';

class RoomProvider extends ChangeNotifier{
  final SocketManager socket = SocketManager(); //방 로그 리스너를 위한 소켓 연결

  _socketListener({required bool isOn}){
    if(isOn){
      socket.on('roomLog', _addRoomLog);
      socket.on('refreshMember', _fetchRoomMembers);
      socket.on('updateLastRead', _updateLastRead);
      socket.on('gradeChanged', _gradeHandler);
    }else{
      socket.off('roomLog', _addRoomLog);
      socket.off('refreshMember', _fetchRoomMembers);
      socket.off('updateLastRead', _updateLastRead);
      socket.off('gradeChanged', _gradeHandler);
    }
  }

  _addRoomLog(dynamic data){
    final log = RoomLog.fromJson(data);
    if(!_roomLog.contains(log)){
      _roomLog.add(log);
      notifyListeners();
    }
  }

  //방 등급 변경
  _gradeHandler(dynamic data){
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final roomId = data['roomId'];
    final grade = data['grade'];
    final uid = data['uid'];

    if(myUid == uid){ //내 정보가 변경된 거라면
      AppRoute.context!.read<ChatProvider>().changedMyGrade(roomId, grade);
    }else{
      _roomMembers[uid]!['grade'] = grade;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketListener(isOn: false);
    super.dispose();
  }

  RoomProvider(){
    _socketListener(isOn: true);
  }

  Map? _room;
  Map? get room => _room;

  setRoom(Map? initRoom){
    _room = initRoom;
    _fetchRoomMembers(null);
    _fetchRoomLogs();
    _fetchLastAnnounce();
    notifyListeners();
  }

  List<RoomLog> _roomLog = [];
  List<RoomLog> get roomLog => _roomLog;

  Map<String, Map> _roomMembers = {};
  Map<String, Map> get roomMembers => _roomMembers;
  Map<String, dynamic> _lastAnnounce = {};
  Map<String, dynamic> get lastAnnounce => _lastAnnounce;

  Future<void> _fetchRoomMembers(dynamic data) async {
    final res = await serverManager.get('roomMember/${_room!['roomId']}');

    if (res.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(res.data);
      final updated = <String, Map>{};
      for (final member in data) {
        final uid = member['uid'];
        if (uid != null) {
          updated[uid] = member; // uid를 키로 전체 데이터 저장
        }
      }

      _roomMembers = updated;
      notifyListeners(); // Provider 또는 ChangeNotifier 등일 경우
    }
  }

  Future<void> _fetchRoomLogs() async{
    if (_room == null || _room!['roomId'] == null) return;
    try{
      final res = await serverManager.get('room/log?roomId=${_room!['roomId']}');

      if (res.statusCode == 200 && res.data != null) {
        _roomLog = List<RoomLog>.from(res.data.map((e)=> RoomLog.fromJson(e)));
        notifyListeners();
      }
    }catch(e){
      print('로그 불러오기 오류 $e');
    }
  }

  Future<void> _fetchLastAnnounce() async {
    if (_room == null || _room!['roomId'] == null) return;

    try {
      final res = await serverManager.get('room/lastAnnounce?roomId=${_room!['roomId']}');

      if (res.statusCode == 200 && res.data != null) {
        _lastAnnounce = res.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('최근 공지 불러오기 실패: $e');
    }
  }

  //방내 채팅 시스템에서 해야하는거
  List<File>? images;
  int? _reply;

  bool _sending = false;
  bool get sending => _sending;

  void sendText(String text) async{
    try{
      _sending = true;
      notifyListeners();

      final chat = {
        'roomId' : _room!['roomId'],
        'contents' : text,
        'type' : 0,
        'reply' : _reply
      };

      await serverManager.post('chat/send', data: chat);
    }finally{
      _sending = false;
      notifyListeners();
    }
  }

  //방 설정 페이지
  Future<String> switchAlarm(bool alarm) async{
    AppRoute.pushLoading();
    String result = '';
    try{
      final res = await serverManager.put('roomMember/alarm', data: {'alarm' : !alarm, 'roomId' : room!['roomId']});

      if(res.statusCode == 201){
        if(alarm){
          result = '이제 알람이 울리지 않아요';
        }else{
          result = '이제부터 알림이 울려요';
        }

        AppRoute.context?.read<ChatProvider>().myMemberUpdate(roomId: room!['roomId'], field: 'alarm', data: !alarm);
      }
    }finally{
      AppRoute.popLoading();
    }
    return result;
  }

  _updateLastRead(dynamic data){
    final uid = data['uid'];
    final auth = FirebaseAuth.instance;
    if(uid != auth.currentUser!.uid){
      final lastRead = data['lastRead'];
      roomMembers[uid]!['lastRead'] = lastRead;
      notifyListeners();
    }
  }


  //방제거
  deleteRoom(BuildContext context) async{
    AppRoute.pushLoading();
    try{
      final chatProvider = context.read<ChatProvider>();
      final router = GoRouter.of(context);
      final roomId = _room!['roomId']!;
      final res = await serverManager.delete('room/$roomId');

      if(res.statusCode == 200){
        await chatProvider.removeRoom(roomId);
        router.go('/my');
        SnackBarManager.showCleanSnackBar(AppRoute.context!, '방이 깔끔하게 정리되었어요.\n다음 만남도 기대할게요!');
      }
    }catch(e){
      print(e);
    }
  }

  //방나가기
  exitRoom(BuildContext context) async{
    AppRoute.pushLoading();
    try{
      final chatProvider = context.read<ChatProvider>();
      final router = GoRouter.of(context);
      final roomId = _room!['roomId']!;
      final res = await serverManager.delete('roomMember/exit/$roomId');

      if(res.statusCode == 200){
        await chatProvider.removeRoom(roomId);
        router.go('/my');
        SnackBarManager.showCleanSnackBar(AppRoute.context!, '방에서 성공적으로 나왔어요\n다음 만남도 기대할게요!');
      }
    }catch(e){
      print(e);
    }
  }

  //사용자 권한 수정
  onChangedMemberGrade(uid, grade) async{
    AppRoute.pushLoading();
    final roomId = _room!['roomId']!;
    final data = {
      'targetUid' : uid,
      'roomId' : roomId,
      'grade' : grade
    };
    await serverManager.put('roomMember/grade', data:  data);
    AppRoute.popLoading();
  }
}