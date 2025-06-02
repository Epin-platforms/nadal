import 'package:flutter/cupertino.dart';
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
  final GlobalKey _globalKey = GlobalKey();
  late RoomsProvider roomsProvider;
  late ChatProvider chatProvider;
  late RoomProvider provider;

  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_){
      _validateAndInitialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    provider.socketListener(isOn: false);
    chatProvider.readReset(widget.roomId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _refreshFromBackground();
    }
  }

  void _validateAndInitialize() {
    if (widget.roomId <= 0) {
      if (mounted) {
        context.pop();
        DialogManager.errorHandler('올바른 접근이 아닙니다');
      }
      return;
    }

    _roomSetting();
  }

  void _refreshFromBackground() async {
    try {
      await chatProvider.refreshRoomFromBackground(widget.roomId);
      await provider.refreshRoomFromBackground();
      await chatProvider.updateMyLastReadInServer(widget.roomId);
      await chatProvider.enterRoomUpdateLastRead(widget.roomId);
    } catch (e) {
      print('백그라운드 복귀 새로고침 오류: $e');
    }
  }

  void _roomSetting() async{
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 방정보 업데이트
      await roomsProvider.updateRoom(widget.roomId);

      // 조인이 안되어있다면 조인
      if(!chatProvider.isJoined(widget.roomId)){
        await chatProvider.joinRoom(widget.roomId);
      }

      // 방 데이터가 없다면 프리뷰로 이동
      final myData = chatProvider.my[widget.roomId];
      if(myData == null){
        await chatProvider.removeRoom(widget.roomId);
        if (mounted) {
          context.pushReplacement('/previewRoom/${widget.roomId}');
        }
        return;
      }

      // 룸데이터 룸 프로바이더에 세팅하기
      if(provider.room == null){
        final rooms = roomsProvider.rooms;
        if (rooms != null && rooms.containsKey(widget.roomId)) {
          final initRoom = rooms[widget.roomId];
          await provider.setRoom(initRoom);
        }
      }

      // 읽은 메시지 업데이트
      await chatProvider.updateMyLastReadInServer(widget.roomId);
      await chatProvider.enterRoomUpdateLastRead(widget.roomId);
    } catch (e) {
      print('방 설정 오류: $e');
      if (mounted) {
        context.pop();
        DialogManager.errorHandler('방 정보를 불러오는데 실패했습니다');
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    roomsProvider = Provider.of<RoomsProvider>(context);
    chatProvider = Provider.of<ChatProvider>(context);
    provider = Provider.of<RoomProvider>(context);

    // 로딩 상태 처리
    if(provider.room == null || _isInitializing){
      return Scaffold(
        body: Center(
          child: NadalCircular(),
        ),
      );
    }

    final roomName = provider.room?['roomName']?.toString() ?? '채팅방';

    return IosPopGesture(
      child: Scaffold(
          key: _globalKey,
          appBar: NadalAppbar(
            centerTitle: false,
            title: roomName,
            actions: [
              NadalIconButton(
                onTap: ()=> context.push('/room/${widget.roomId}/schedule'),
                icon: BootstrapIcons.calendar2,
                size: 22.r,
              ),
              SizedBox(width: 8.w,),
              NadalIconButton(
                onTap: ()=> context.push('/room/${widget.roomId}/information'),
                icon: BootstrapIcons.list,
              )
            ],
          ),
          body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                          child: ChatList(
                            roomProvider: provider,
                          )
                      ),
                      SizedBox(height: 10.h,),
                      ChatField(roomProvider: provider,),
                    ],
                  ),
                  if(provider.lastAnnounce.isNotEmpty)
                    Positioned(
                        top: 0, right: 0, left: 0,
                        child: RoomAnnouncedWidget(announce: provider.lastAnnounce)
                    )
                ],
              )
          )
      ),
    );
  }
}