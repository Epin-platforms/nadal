import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/room/Room_Log.dart';

import '../../manager/server/Socket_Manager.dart';

class RoomProvider extends ChangeNotifier{
  final int MAX_IMAGE_LENGTH = 5;
  final SocketManager socket = SocketManager();

  void socketListener({required bool isOn}){
    if(isOn){
      socket.on('roomLog', _addRoomLog);
      socket.on('refreshMember', _fetchRoomMembers);
      socket.on('updateLastRead', _updateLastRead);
      socket.on('gradeChanged', _gradeHandler);
      socket.on('announce', _getAnnounce);
    }else{
      socket.off('roomLog', _addRoomLog);
      socket.off('refreshMember', _fetchRoomMembers);
      socket.off('updateLastRead', _updateLastRead);
      socket.off('gradeChanged', _gradeHandler);
      socket.off('announce', _getAnnounce);
    }
  }

  void _getAnnounce(dynamic data){
    _fetchLastAnnounce();
  }

  void _addRoomLog(dynamic data){
    try {
      if(data != null && data is List && data.isNotEmpty){
        final log = RoomLog.fromJson(data[0]);
        final existingLogIndex = _roomLog.indexWhere((e) => e.logId == log.logId);
        if(existingLogIndex == -1){
          _roomLog.add(log);
          notifyListeners();
        }
      }
    } catch (e) {
      print('룸 로그 추가 오류: $e');
    }
  }

  void _gradeHandler(dynamic data){
    try {
      if (data == null) return;

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      final roomId = data['roomId'] as int?;
      final grade = data['grade'] as int?;
      final uid = data['uid'] as String?;

      if (roomId == null || grade == null || uid == null) return;

      final context = AppRoute.context;
      if (context?.mounted != true) return;

      if(myUid == uid){
        context!.read<ChatProvider>().changedMyGrade(roomId, grade);
      }else{
        final member = _roomMembers[uid];
        if (member != null) {
          member['grade'] = grade;
          notifyListeners();
        }
      }
    } catch (e) {
      print('등급 변경 처리 오류: $e');
    }
  }

  Map? _room;
  Map? get room => _room;

  Future setRoom(Map? initRoom) async{
    try {
      _room = initRoom;
      socketListener(isOn: true);
      await _fetchRoomMembers(null);
      await _fetchRoomLogs();
      await _fetchLastAnnounce();
      notifyListeners();
    } catch (e) {
      print('방 설정 오류: $e');
    }
  }

  List<RoomLog> _roomLog = [];
  List<RoomLog> get roomLog => _roomLog;

  Map<String, Map> _roomMembers = {};
  Map<String, Map> get roomMembers => _roomMembers;
  Map<String, dynamic> _lastAnnounce = {};
  Map<String, dynamic> get lastAnnounce => _lastAnnounce;

  Future<void> _fetchRoomMembers(dynamic data) async {
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final res = await serverManager.get('roomMember/$roomId');

      if (res.statusCode == 200 && res.data != null) {
        final data = List<Map<String, dynamic>>.from(res.data);
        final updated = <String, Map>{};

        for (final member in data) {
          final uid = member['uid'] as String?;
          if (uid != null) {
            updated[uid] = member;
          }
        }

        _roomMembers = updated;
        notifyListeners();
      }
    } catch (e) {
      print('방 멤버 가져오기 오류: $e');
    }
  }

  Future<void> _fetchRoomLogs() async{
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final res = await serverManager.get('room/log?roomId=$roomId');

      if (res.statusCode == 200 && res.data != null) {
        final logsData = res.data as List;
        _roomLog = logsData
            .map((e) => RoomLog.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('로그 불러오기 오류: $e');
    }
  }

  Future<void> _fetchLastAnnounce() async {
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      _lastAnnounce = {};
      notifyListeners();

      final res = await serverManager.get('room/lastAnnounce?roomId=$roomId');

      if (res.statusCode == 200 && res.data != null) {
        _lastAnnounce = Map<String, dynamic>.from(res.data);
        notifyListeners();
      }
    } catch (e) {
      print('최근 공지 불러오기 실패: $e');
    }
  }

  int? _reply;
  int? get reply => _reply;

  void setReply(int? value){
    _reply = value;
    notifyListeners();
  }

  bool _sending = false;
  bool get sending => _sending;

  void sendText(String text) async{
    if (text.trim().isEmpty) return;

    try{
      _sending = true;
      notifyListeners();

      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final chat = {
        'roomId' : roomId,
        'contents' : text.trim(),
        'type' : 0,
        'reply' : _reply
      };

      await serverManager.post('chat/send', data: chat);
    } catch (e) {
      print('텍스트 전송 오류: $e');
    } finally{
      _sending = false;
      notifyListeners();
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<List<File>> getImages() async {
    try {
      List<File> pickedImage = [];
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return [];

      for (XFile image in images) {
        pickedImage.add(File(image.path));
      }

      return pickedImage;
    } catch (e) {
      print('이미지 선택 오류: $e');
      return [];
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (e) {
      print('카메라 이미지 선택 오류: $e');
      return null;
    }
  }

  List<File> _sendingImage = [];
  List<File> get sendingImage => _sendingImage;

  void sendImage() async{
    if (_sendingImage.isNotEmpty) return;

    try{
      final images = await getImages();
      if(images.isEmpty) return;

      if(images.length > MAX_IMAGE_LENGTH){
        DialogManager.showBasicDialog(
            title: '앗 이런...',
            content: '이미지는 최대 5장까지만 가능해요',
            confirmText: '확인'
        );
        return;
      }

      _sendingImage = images;
      notifyListeners();

      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('roomId', roomId.toString()),
        MapEntry('type', '1'),
      ]);

      for (final image in images.take(5)) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
                image.path,
                filename: image.path.split('/').last
            ),
          ),
        );
      }

      await serverManager.post('chat/send', data: formData);
    }catch(error){
      print('이미지 전송 오류: $error');
    }finally{
      _sendingImage.clear();
      notifyListeners();
    }
  }

  void sentImageByCamera() async{
    if (_sendingImage.isNotEmpty) return;

    try{
      final image = await pickImageFromCamera();
      if(image == null) return;

      _sendingImage.add(image);
      notifyListeners();

      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('roomId', roomId.toString()),
        MapEntry('type', '1'),
      ]);

      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last
          ),
        ),
      );

      await serverManager.post('chat/send', data: formData);
    }catch(error){
      print('카메라 이미지 전송 오류: $error');
    }finally{
      _sendingImage.clear();
      notifyListeners();
    }
  }

  Future<String> switchAlarm(bool alarm) async{
    AppRoute.pushLoading();
    String result = '';

    try{
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) {
        result = '방 정보를 찾을 수 없어요';
        return result;
      }

      final res = await serverManager.put('roomMember/alarm', data: {
        'alarm' : !alarm,
        'roomId' : roomId
      });

      if(res.statusCode == 201){
        result = alarm ? '이제 알람이 울리지 않아요' : '이제부터 알림이 울려요';

        final context = AppRoute.context;
        if (context?.mounted == true) {
          context!.read<ChatProvider>().myMemberUpdate(
              roomId: roomId,
              field: 'alarm',
              data: !alarm ? 1 : 0
          );
        }
      }
    } catch (e) {
      print('알람 설정 변경 오류: $e');
      result = '설정 변경에 실패했어요';
    } finally{
      AppRoute.popLoading();
    }
    return result;
  }

  void _updateLastRead(dynamic data){
    try {
      if (data == null) return;

      final uid = data['uid'] as String?;
      final auth = FirebaseAuth.instance;

      if(uid == null || uid == auth.currentUser?.uid) return;

      final lastRead = data['lastRead'] as int?;
      if (lastRead == null) return;

      final member = _roomMembers[uid];
      if (member != null) {
        member['lastRead'] = lastRead;
        notifyListeners();
      }
    } catch (e) {
      print('읽음 상태 업데이트 오류: $e');
    }
  }

  Future<void> deleteRoom(BuildContext context) async{
    AppRoute.pushLoading();

    try{
      final chatProvider = context.read<ChatProvider>();
      final router = GoRouter.of(context);
      final roomId = _room?['roomId'] as int?;

      if (roomId == null) return;

      final res = await serverManager.delete('room/$roomId');

      if(res.statusCode == 200){
        await chatProvider.removeRoom(roomId);
        router.go('/my');
        SnackBarManager.showCleanSnackBar(
            AppRoute.context!,
            '방이 깔끔하게 정리되었어요.\n다음 만남도 기대할게요!'
        );
      }
    }catch(e){
      print('방 삭제 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> exitRoom(BuildContext context) async{
    AppRoute.pushLoading();

    try{
      final chatProvider = context.read<ChatProvider>();
      final router = GoRouter.of(context);
      final roomId = _room?['roomId'] as int?;

      if (roomId == null) return;

      final res = await serverManager.delete('roomMember/exit/$roomId');

      if(res.statusCode == 200){
        await chatProvider.removeRoom(roomId);
        router.go('/my');
        SnackBarManager.showCleanSnackBar(
            AppRoute.context!,
            '방에서 성공적으로 나왔어요\n다음 만남도 기대할게요!'
        );
      }
    }catch(e){
      print('방 나가기 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> onChangedMemberGrade(String uid, int grade) async{
    AppRoute.pushLoading();

    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final data = {
        'targetUid' : uid,
        'roomId' : roomId,
        'grade' : grade
      };

      await serverManager.put('roomMember/grade', data: data);
    } catch (e) {
      print('멤버 등급 변경 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  List<String> filterInviteAbleUsers(List<String> uid){
    try {
      return uid.where((e) => !_roomMembers.keys.contains(e)).toList();
    } catch (e) {
      print('초대 가능한 사용자 필터링 오류: $e');
      return [];
    }
  }

  Future<void> refreshRoomFromBackground() async {
    try {
      await _fetchRoomMembers(null);
      await _fetchRoomLogs();
      await _fetchLastAnnounce();
    } catch (e) {
      print('방 데이터 백그라운드 새로고침 오류: $e');
    }
  }
}