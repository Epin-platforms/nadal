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
  final GlobalKey _globalKey = GlobalKey();
  late RoomsProvider roomsProvider;
  late ChatProvider chatProvider;
  late RoomProvider provider;

  bool _isInitializing = false;
  bool _hasInitializedLastRead = false; // 🔧 lastRead 초기화 상태 추적
  late final bool isOpen;

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

    // 🔧 방을 나갈 때 마지막으로 한 번 더 lastRead 업데이트
    if (_hasInitializedLastRead) {
      print('나가면서 마지막 읽은 채팅 업데이트됨');
      chatProvider.updateLastRead(widget.roomId);
    }

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

      // 🔧 백그라운드 복귀 시에도 lastRead 업데이트
      await _updateLastReadWithRetry();
    } catch (e) {
      print('❌ 백그라운드 복귀 새로고침 오류: $e');
    }
  }

  // 🔧 새로운 메서드: lastRead 업데이트 재시도 로직
  Future<void> _updateLastReadWithRetry() async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('🔄 lastRead 업데이트 시도 ${retryCount + 1}/$maxRetries');

        // 데이터 준비 상태 확인
        if (!_isDataReady()) {
          print('⚠️ 데이터가 준비되지 않음, 500ms 대기');
          await Future.delayed(Duration(milliseconds: 500));
          retryCount++;
          continue;
        }

        // lastRead 업데이트 실행
        await chatProvider.updateLastRead(widget.roomId);

        _hasInitializedLastRead = true;
        print('✅ lastRead 업데이트 성공');
        break;

      } catch (e) {
        retryCount++;
        print('❌ lastRead 업데이트 실패 (${retryCount}/$maxRetries): $e');

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }
    }

    if (retryCount >= maxRetries) {
      print('❌ lastRead 업데이트 최대 재시도 횟수 초과');
    }
  }

  // 🔧 새로운 메서드: 데이터 준비 상태 확인
  bool _isDataReady() {
    final myData = chatProvider.my[widget.roomId];
    final chats = chatProvider.chat[widget.roomId];

    return myData != null && chats != null;
  }

  void _roomSetting() async{
    if (_isInitializing) return;

    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    try {
      print('🚀 방 설정 시작 (roomId: ${widget.roomId})');

      // 방정보 업데이트
      isOpen = await roomsProvider.updateRoom(widget.roomId) ?? false;
      print('✅ 방 업데이트 완료 - roomId: ${widget.roomId}');

      // 조인이 안되어있다면 조인
      if(!chatProvider.isJoined(widget.roomId)){
        await chatProvider.joinRoom(widget.roomId);
        print('✅ 소켓에 조인됨');
      }

      // 방 데이터가 없다면 프리뷰로 이동
      final myData = chatProvider.my[widget.roomId];
      print('📊 현방에서의 내 데이터: $myData');

      if(myData == null){
        await chatProvider.removeRoom(widget.roomId);
        if (mounted) {
          context.pushReplacement('/previewRoom/${widget.roomId}');
        }
        return;
      }

      // 룸데이터 룸 프로바이더에 세팅하기
      if(provider.room == null){
        print('🔧 프로바이더에 룸이 적용안되어 재설정 실행');
        final rooms = roomsProvider.rooms;
        final quickRooms = roomsProvider.quickRooms!;

        if (rooms != null && (rooms.containsKey(widget.roomId) || quickRooms.containsKey(widget.roomId))) {
          final initRoom = isOpen ? quickRooms[widget.roomId] : rooms[widget.roomId];
          await provider.setRoom(initRoom);
        }
      }

      // 🔧 개선된 lastRead 업데이트 로직
      print('🔄 lastRead 업데이트 시작');

      // 데이터가 완전히 로드될 때까지 대기
      await Future.delayed(Duration(milliseconds: 100));

      // lastRead 업데이트 실행
      await _updateLastReadWithRetry();

      print('✅ 방 설정 완료');

    } catch (e) {
      print('❌ 방 설정 오류: $e');
      if (mounted) {
        context.pop();
        DialogManager.errorHandler('방 정보를 불러오는데 실패했습니다');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      print('🔄 _isInitializing = false 설정됨');
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
              SizedBox(width: 8.w),
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
                      if(provider.lastAnnounce.isNotEmpty)
                        SizedBox(height: 60.h),
                        Expanded(
                            child: ChatList(
                              roomProvider: provider,
                            )
                        ),
                      SizedBox(height: 10.h),
                      ChatField(roomProvider: provider),
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