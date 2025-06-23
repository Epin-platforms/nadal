import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/room/Room_Log.dart';
import '../../manager/server/Socket_Manager.dart';

class RoomProvider extends ChangeNotifier {
  final SocketManager socket = SocketManager();
  final ImagePicker _picker = ImagePicker();

  // 방 정보
  Map? _room;
  Map<String, Map> _roomMembers = {};
  List<RoomLog> _roomLog = [];
  Map<String, dynamic> _lastAnnounce = {};

  // 상태
  int? _reply;
  bool _sending = false;
  List<File> _sendingImage = [];

  // 🔧 **수정: 소켓 리스너 상태 관리 개선**
  bool _isSocketListenerAttached = false;
  Timer? _reattachTimer;

  // Getters
  Map? get room => _room;
  Map<String, Map> get roomMembers => _roomMembers;
  List<RoomLog> get roomLog => _roomLog;
  Map<String, dynamic> get lastAnnounce => _lastAnnounce;
  int? get reply => _reply;
  bool get sending => _sending;
  List<File> get sendingImage => _sendingImage;

  // 방 설정 및 초기 데이터 로드
  Future<void> setRoom(Map? initRoom) async {
    try {
      _room = initRoom;
      if (_room != null) {
        await _loadRoomData();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 방 설정 오류: $e');
    }
  }

  // 방 관련 데이터 로드
  Future<void> _loadRoomData() async {
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      await Future.wait([
        _fetchRoomMembers(),
        _fetchRoomLogs(),
        _fetchLastAnnounce(),
      ]);
    } catch (e) {
      debugPrint('❌ 방 데이터 로드 오류: $e');
    }
  }

  // 🔧 **수정: 소켓 리스너 설정/해제 개선**
  void socketListener({required bool isOn}) {
    if (isOn && !_isSocketListenerAttached) {
      _attachSocketListeners();
    } else if (!isOn && _isSocketListenerAttached) {
      _detachSocketListeners();
    }
  }

  // 🔧 **수정: 소켓 리스너 연결 (개선된 안전성 체크)**
  void _attachSocketListeners() {
    try {
      // 🔧 **수정: RoomProvider 전용 리스너 등록 메서드 사용**
      socket.on('roomLog', _addRoomLog);
      socket.on('refreshMember', _fetchRoomMembers);
      socket.on('updateLastRead', _updateLastRead);
      socket.on('gradeChanged', _gradeHandler);
      socket.on('announce', _getAnnounce);

      _isSocketListenerAttached = true;
      _cancelReattachTimer();
      debugPrint('✅ RoomProvider 소켓 리스너 연결 완료');
    } catch (e) {
      debugPrint('❌ RoomProvider 소켓 리스너 연결 실패: $e');
      _isSocketListenerAttached = false;
      _scheduleReattach();
    }
  }

  // 🔧 **추가: 리스너 재연결 스케줄링**
  void _scheduleReattach() {
    _cancelReattachTimer();
    _reattachTimer = Timer(const Duration(seconds: 2), () {
      if (_room != null && !_isSocketListenerAttached) {
        debugPrint('🔄 RoomProvider: 리스너 재연결 시도');
        _attachSocketListeners();
      }
    });
  }

  // 🔧 **추가: 재연결 타이머 취소**
  void _cancelReattachTimer() {
    _reattachTimer?.cancel();
    _reattachTimer = null;
  }

  // 🔧 소켓 리스너 해제
  void _detachSocketListeners() {
    try {
      socket.off('roomLog');
      socket.off('refreshMember');
      socket.off('updateLastRead');
      socket.off('gradeChanged');
      socket.off('announce');

      _isSocketListenerAttached = false;
      _cancelReattachTimer();
      debugPrint('✅ RoomProvider 소켓 리스너 해제 완료');
    } catch (e) {
      debugPrint('❌ RoomProvider 소켓 리스너 해제 실패: $e');
    }
  }

  // 🔧 **수정: 소켓 리스너 재설정 (재연결 시 호출) - 안전성 강화**
  Future<void> reconnectSocket() async{
    if (_room == null) {
      debugPrint('⚠️ RoomProvider: 방 정보가 없어 리스너 재설정 스킵');
      return;
    }

    await refreshRoomFromBackground();
    debugPrint('🔄 RoomProvider 소켓 리스너 재설정');
  }

  // 방 멤버 정보 가져오기
  Future<void> _fetchRoomMembers([dynamic data]) async {
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final res = await serverManager.get('roomMember/$roomId');
      if (res.statusCode == 200 && res.data != null) {
        final members = List<Map<String, dynamic>>.from(res.data);
        final updated = <String, Map>{};

        for (final member in members) {
          final uid = member['uid'] as String?;
          if (uid != null) {
            updated[uid] = member;
          }
        }

        _roomMembers = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ 방 멤버 가져오기 오류: $e');
    }
  }

  // 방 로그 가져오기
  Future<void> _fetchRoomLogs() async {
    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final res = await serverManager.get('room/log?roomId=$roomId');
      if (res.statusCode == 200 && res.data != null) {
        final logsData = res.data as List;
        _roomLog = logsData.map((e) => RoomLog.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ 로그 불러오기 오류: $e');
    }
  }

  // 공지사항 가져오기
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
      debugPrint('❌ 최근 공지 불러오기 실패: $e');
    }
  }

  // 소켓 이벤트 핸들러들
  void _addRoomLog(dynamic data) {
    try {
      if (data != null && data is List && data.isNotEmpty) {
        final log = RoomLog.fromJson(data[0]);
        final existingIndex = _roomLog.indexWhere((e) => e.logId == log.logId);
        if (existingIndex == -1) {
          _roomLog.add(log);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ 룸 로그 추가 오류: $e');
    }
  }

  void _gradeHandler(dynamic data) {
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

      if (myUid == uid) {
        context!.read<ChatProvider>().changedMyGrade(roomId, grade);
      } else {
        final member = _roomMembers[uid];
        if (member != null) {
          member['grade'] = grade;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ 등급 변경 처리 오류: $e');
    }
  }

  void _updateLastRead(dynamic data) {
    try {
      if (data == null) return;

      final uid = data['uid'] as String?;
      final auth = FirebaseAuth.instance;

      if (uid == null || uid == auth.currentUser?.uid) return;

      final lastRead = data['lastRead'] as int?;
      if (lastRead == null) return;

      final member = _roomMembers[uid];
      if (member != null) {
        member['lastRead'] = lastRead;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ 읽음 상태 업데이트 오류: $e');
    }
  }

  void _getAnnounce(dynamic data) {
    _fetchLastAnnounce();
  }

  // 답장 설정
  void setReply(int? value) {
    _reply = value;
    notifyListeners();
  }

  // 🔧 **수정: 텍스트 메시지 전송 (연결 상태 확인 강화)**
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty || _sending) return;

    try {
      _sending = true;
      notifyListeners();

      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final chat = {
        'roomId': roomId,
        'contents': text.trim(),
        'type': 0,
        'reply': _reply
      };

      await serverManager.post('chat/send', data: chat);
    } catch (e) {
      debugPrint('❌ 텍스트 전송 오류: $e');
      rethrow; // 상위에서 에러 처리하도록
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // 이미지 선택 (갤러리) - 권한 체크 제거 (상위에서 이미 확인함)
  Future<List<File>> _getImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('❌ 이미지 선택 오류: $e');

      // 🔧 더 구체적인 에러 처리
      if (e.toString().contains('photo_access_denied') ||
          e.toString().contains('camera_access_denied')) {
        throw Exception('권한이 거부되었습니다');
      }

      throw Exception('이미지를 선택할 수 없습니다');
    }
  }

  // 이미지 선택 (카메라) - 권한 체크 제거 (상위에서 이미 확인함)
  Future<File?> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // 🔧 이미지 품질 조정으로 용량 최적화
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('❌ 카메라 이미지 선택 오류: $e');

      // 🔧 더 구체적인 에러 처리
      if (e.toString().contains('camera_access_denied')) {
        throw Exception('카메라 권한이 거부되었습니다');
      }

      throw Exception('카메라를 사용할 수 없습니다');
    }
  }

  // 이미지 전송 (갤러리)
  Future<void> sendImage() async {
    if (_sendingImage.isNotEmpty) return;

    try {
      final images = await _getImages();
      if (images.isEmpty) {
        // 🔧 사용자가 선택하지 않은 경우는 에러가 아님
        debugPrint('사용자가 이미지를 선택하지 않음');
        return;
      }

      if (images.length > 5) {
        DialogManager.showBasicDialog(
            title: '앗 이런...',
            content: '이미지는 최대 5장까지만 가능해요',
            confirmText: '확인'
        );
        return;
      }

      await _uploadImages(images);
    } catch (e) {
      debugPrint('❌ 이미지 전송 오류: $e');
      _clearSendingImages();
      rethrow;
    }
  }


  // 이미지 전송 (카메라)
  Future<void> sentImageByCamera() async {
    if (_sendingImage.isNotEmpty) return;

    try {
      final image = await _pickImageFromCamera();
      if (image == null) {
        // 🔧 사용자가 취소한 경우는 에러가 아님
        debugPrint('사용자가 카메라 촬영을 취소함');
        return;
      }

      await _uploadImages([image]);
    } catch (e) {
      debugPrint('❌ 카메라 이미지 전송 오류: $e');
      _clearSendingImages();
      rethrow;
    }
  }

  // 이미지 업로드
  Future<void> _uploadImages(List<File> images) async {
    try {
      _sendingImage = images;
      notifyListeners();

      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final formData = FormData();
      formData.fields.addAll([
        MapEntry('roomId', roomId.toString()),
        MapEntry('type', '1'),
      ]);

      for (final image in images) {
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
    } finally {
      _clearSendingImages();
    }
  }

  // 전송 중인 이미지 정리
  void _clearSendingImages() {
    _sendingImage.clear();
    notifyListeners();
  }

  // 알람 설정 변경
  Future<String> switchAlarm(bool alarm) async {
    AppRoute.pushLoading();
    String result = '';

    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) {
        result = '방 정보를 찾을 수 없어요';
        return result;
      }

      final res = await serverManager.put('roomMember/alarm', data: {
        'alarm': !alarm,
        'roomId': roomId
      });

      if (res.statusCode == 201) {
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
      debugPrint('❌ 알람 설정 변경 오류: $e');
      result = '설정 변경에 실패했어요';
    } finally {
      AppRoute.popLoading();
    }
    return result;
  }

  // 방 삭제
  Future<void> deleteRoom(BuildContext context) async {
    AppRoute.pushLoading();

    try {
      final chatProvider = context.read<ChatProvider>();
      final roomsProvider = context.read<RoomsProvider>();
      final router = GoRouter.of(context);
      final roomId = _room?['roomId'] as int?;

      if (roomId == null) return;

      final res = await serverManager.delete('room/$roomId');

      if (res.statusCode == 200) {
        roomsProvider.removeRoom(roomId);
        await chatProvider.removeRoom(roomId);
        router.go('/my');
        SnackBarManager.showCleanSnackBar(
            AppRoute.context!,
            '방이 깔끔하게 정리되었어요.\n다음 만남도 기대할게요!'
        );
      }
    } catch (e) {
      debugPrint('❌ 방 삭제 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  // 방 나가기
  Future<void> exitRoom(BuildContext context) async {
    AppRoute.pushLoading();

    try {
      final isOpen = _room?['isOpen'] == 1;
      final roomsProvider = context.read<RoomsProvider>();
      final chatProvider = context.read<ChatProvider>();
      final router = GoRouter.of(context);
      final roomId = _room?['roomId'] as int?;

      if (roomId == null) return;

      final res = await serverManager.delete('roomMember/exit/$roomId');

      if (res.statusCode == 200) {
        roomsProvider.removeRoom(roomId);
        await chatProvider.removeRoom(roomId);
        isOpen ? router.go('/quick-chat') : router.go('/my');
        SnackBarManager.showCleanSnackBar(
            AppRoute.context!,
            '방에서 성공적으로 나왔어요\n다음 만남도 기대할게요!'
        );
      }
    } catch (e) {
      debugPrint('❌ 방 나가기 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  // 멤버 등급 변경
  Future<void> onChangedMemberGrade(String uid, int grade) async {
    AppRoute.pushLoading();

    try {
      final roomId = _room?['roomId'] as int?;
      if (roomId == null) return;

      final data = {
        'targetUid': uid,
        'roomId': roomId,
        'grade': grade
      };

      await serverManager.put('roomMember/grade', data: data);
    } catch (e) {
      debugPrint('❌ 멤버 등급 변경 오류: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  // 초대 가능한 사용자 필터링
  List<String> filterInviteAbleUsers(List<String> uid) {
    try {
      return uid.where((e) => !_roomMembers.keys.contains(e)).toList();
    } catch (e) {
      debugPrint('❌ 초대 가능한 사용자 필터링 오류: $e');
      return [];
    }
  }

  // 🔧 **수정: 백그라운드에서 방 데이터 새로고침 (간단화)**
  Future<void> refreshRoomFromBackground() async {
    try {
      // 백그라운드 복귀 시에는 기본 데이터만 새로고침
      await Future.wait([
        _fetchRoomMembers(),
        _fetchLastAnnounce(),
      ]);

      debugPrint('✅ RoomProvider 백그라운드 새로고침 완료');
    } catch (e) {
      debugPrint('❌ 방 데이터 백그라운드 새로고침 오류: $e');
    }
  }

  @override
  void dispose() {
    // 소켓 리스너 해제
    _detachSocketListeners();
    _cancelReattachTimer();
    super.dispose();
  }
}