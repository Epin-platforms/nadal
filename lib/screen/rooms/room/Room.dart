import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/Chat_Field.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/Chat_List.dart';
import 'package:my_sports_calendar/screen/rooms/room/widget/Room_Announced_Widget.dart';

import '../../../manager/project/Import_Manager.dart';

class Room extends StatefulWidget {
  const Room({super.key, required this.roomId});
  final int roomId;

  @override
  State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> with WidgetsBindingObserver {
  late RoomsProvider roomsProvider;
  late ChatProvider chatProvider;
  late RoomProvider roomProvider;

  bool _isInitialized = false;
  bool _hasReadUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoom();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 방 나갈 때 읽음 상태 업데이트
    if (_hasReadUpdate) {
      chatProvider.updateLastRead(widget.roomId);
    }

    // 소켓 리스너 해제
    roomProvider.socketListener(isOn: false);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshFromBackground();
    }
  }

  // 방 초기화
  Future<void> _initializeRoom() async {
    if (_isInitialized) return;

    try {
      print('🚀 방 초기화 시작: ${widget.roomId}');

      // 유효성 검사
      if (widget.roomId <= 0) {
        _handleError('올바른 접근이 아닙니다');
        return;
      }

      roomsProvider = context.read<RoomsProvider>();
      chatProvider = context.read<ChatProvider>();
      roomProvider = context.read<RoomProvider>();

      // 1. 방 정보 업데이트
      final isOpen = await roomsProvider.updateRoom(widget.roomId);
      print('✅ 방 정보 업데이트 완료');

      // 2. 채팅 데이터 확인
      if (!chatProvider.isJoined(widget.roomId)) {
        _handleError('방에 참가되어 있지 않습니다');
        return;
      }

      // 3. 내 정보 확인
      final myData = chatProvider.my[widget.roomId];
      if (myData == null) {
        context.pushReplacement('/previewRoom/${widget.roomId}');
        return;
      }

      // 4. 방 프로바이더 설정
      if (roomProvider.room == null) {
        final rooms = isOpen == true ? roomsProvider.quickRooms : roomsProvider.rooms;
        final roomData = rooms?[widget.roomId];
        if (roomData != null) {
          await roomProvider.setRoom(roomData);
        }
      }

      // 5. 소켓 리스너 설정
      roomProvider.socketListener(isOn: true);

      // 6. 읽음 상태 업데이트
      await chatProvider.updateLastRead(widget.roomId);
      _hasReadUpdate = true;

      _isInitialized = true;
      print('✅ 방 초기화 완료: ${widget.roomId}');

    } catch (e) {
      print('❌ 방 초기화 실패: $e');
      _handleError('방 정보를 불러오는데 실패했습니다');
    }
  }

  // 백그라운드 복귀 처리
  Future<void> _refreshFromBackground() async {
    try {
      await chatProvider.refreshRoomFromBackground(widget.roomId);
      await roomProvider.refreshRoomFromBackground();

      // 읽음 상태 업데이트
      await chatProvider.updateLastRead(widget.roomId);
    } catch (e) {
      print('❌ 백그라운드 복귀 새로고침 오류: $e');
    }
  }

  // 에러 처리
  void _handleError(String message) {
    if (mounted) {
      context.pop();
      DialogManager.errorHandler(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화되지 않았거나 방 정보가 없으면 로딩
    if (!_isInitialized || context.watch<RoomProvider>().room == null) {
      return Scaffold(
        body: Center(child: NadalCircular()),
      );
    }

    final roomName = context.watch<RoomProvider>().room?['roomName']?.toString() ?? '채팅방';
    final lastAnnounce = context.watch<RoomProvider>().lastAnnounce;

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          centerTitle: false,
          title: roomName,
          actions: [
            NadalIconButton(
              onTap: () => context.push('/room/${widget.roomId}/schedule'),
              icon: BootstrapIcons.calendar2,
              size: 22.r,
            ),
            SizedBox(width: 8.w),
            NadalIconButton(
              onTap: () => context.push('/room/${widget.roomId}/information'),
              icon: BootstrapIcons.list,
            )
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 공지사항 공간 확보
                  if (lastAnnounce.isNotEmpty)
                    SizedBox(height: 60.h),

                  // 채팅 리스트
                  Expanded(
                    child: ChatList(roomProvider: context.read<RoomProvider>()),
                  ),

                  SizedBox(height: 10.h),

                  // 채팅 입력창
                  ChatField(roomProvider: context.read<RoomProvider>()),
                ],
              ),

              // 공지사항 (상단 고정)
              if (lastAnnounce.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: RoomAnnouncedWidget(announce: lastAnnounce),
                ),
            ],
          ),
        ),
      ),
    );
  }
}