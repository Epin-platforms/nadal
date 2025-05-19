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

class _RoomState extends State<Room> {
  final GlobalKey _globalKey = GlobalKey();
  late RoomsProvider roomsProvider;
  late ChatProvider chatProvider;
  late RoomProvider provider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.roomId == -1){
        context.pop();
        DialogManager.errorHandler('올바른 접근이 아닙니다');
        return;
      }

      _roomSetting();
    });
    super.initState();
  }


  void _roomSetting() async{
    //방정보 업데이트
    await roomsProvider.updateRoom(widget.roomId);

    //만약 업데이트가 조인이 안되어있다면 조인 및 기타 내용 설정
    if(!chatProvider.isJoined(widget.roomId)){
      await chatProvider.joinRoom(widget.roomId);
    }

    //그래도 없다면 조인 삭제 및 플레이스 변경
    if(chatProvider.my[widget.roomId] == null){
      await chatProvider.removeRoom(widget.roomId);
      context.pushReplacement('room/preview/${widget.roomId}');
    }

    //룸데이터 룸 프로바이더에 세팅하기
    if(provider.room == null){
      final initRoom = roomsProvider.rooms![widget.roomId];
      await provider.setRoom(initRoom);
    }

    //읽은 메시지 업데이트
    chatProvider.updateMyLastReadInServer(widget.roomId);
    chatProvider.enterRoomUpdateLastRead(widget.roomId);
  }


  @override
  Widget build(BuildContext context) {
    roomsProvider = Provider.of<RoomsProvider>(context);
    chatProvider = Provider.of<ChatProvider>(context);
    provider = Provider.of<RoomProvider>(context);


    if(provider.room == null){
      return Center(
        child: NadalCircular(),
      );
    }


    return IosPopGesture(
      child: Scaffold(
          key: _globalKey,
          appBar: NadalAppbar(
            centerTitle: false,
            title: provider.room?['roomName'] ?? '',
            actions: [
              NadalIconButton(
                  onTap: ()=> context.push('/room/${widget.roomId}/schedule'),
                  icon: BootstrapIcons.calendar2,
                  size: 22,
              ),
              SizedBox(width: 8,),
              NadalIconButton(
                  onTap: ()=> context.push('/room/${widget.roomId}/information'),
                icon: BootstrapIcons.list,
              )
            ],
          ),
          body: SafeArea(
              child:
              provider.room == null ?
              Container() :
              Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                          child: ChatList(
                            roomProvider: provider,
                          )
                      ),
                      SizedBox(height: 10,),
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
