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

  // 🔧 상태 관리 개선
  bool _isInitializing = false;
  bool _hasInitializedLastRead = false;
  bool _isDisposed = false;
  late final bool isOpen;

  // 🔧 lastRead 업데이트 관리
  Timer? _lastReadUpdateTimer;
  bool _needsLastReadUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _validateAndInitialize();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    // 🔧 정리 작업 순서 개선
    _cancelLastReadTimer();

    provider.socketListener(isOn: false);
    chatProvider.readReset(widget.roomId);

    // 🔧 마지막 lastRead 업데이트 (비동기로 처리하되 dispose에서는 fire-and-forget)
    if (_hasInitializedLastRead && !_isDisposed) {
      _updateLastReadSafely();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && !_isDisposed) {
      _refreshFromBackground();
    } else if (state == AppLifecycleState.paused && _hasInitializedLastRead) {
      // 🔧 앱이 백그라운드로 갈 때도 lastRead 업데이트
      _updateLastReadSafely();
    }
  }

  void _validateAndInitialize() {
    if (_isDisposed) return;

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
    if (_isDisposed) return;

    try {
      await chatProvider.refreshRoomFromBackground(widget.roomId);
      await provider.refreshRoomFromBackground();

      // 🔧 백그라운드 복귀 시 lastRead 업데이트 스케줄링
      _scheduleLastReadUpdate();
    } catch (e) {
      print('❌ 백그라운드 복귀 새로고침 오류: $e');
    }
  }

  // 🔧 lastRead 업데이트 스케줄링
  Future<void> _scheduleLastReadUpdate() async{
    if (_isDisposed || !_hasInitializedLastRead) return;

    _needsLastReadUpdate = true;
    _cancelLastReadTimer();

    // 500ms 후 업데이트 (디바운싱)
    _lastReadUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed && _needsLastReadUpdate) {
        _updateLastReadSafely();
        _needsLastReadUpdate = false;
      }
    });
  }

  // 🔧 타이머 취소
  void _cancelLastReadTimer() {
    _lastReadUpdateTimer?.cancel();
    _lastReadUpdateTimer = null;
  }

  // 🔧 안전한 lastRead 업데이트
  void _updateLastReadSafely() {
    if (_isDisposed) return;

    try {
      chatProvider.updateLastRead(widget.roomId);
      print('✅ lastRead 업데이트 완료');
    } catch (e) {
      print('❌ lastRead 업데이트 오류: $e');
    }
  }

  // 🔧 데이터 준비 상태 확인
  bool _isDataReady() {
    try {
      final myData = chatProvider.my[widget.roomId];
      final chats = chatProvider.chat[widget.roomId];
      final isJoined = chatProvider.isJoined(widget.roomId);

      return myData != null && chats != null && isJoined;
    } catch (e) {
      print('❌ 데이터 준비 상태 확인 오류: $e');
      return false;
    }
  }

  void _roomSetting() async {
    if (_isInitializing || _isDisposed) return;

    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    try {
      print('🚀 방 설정 시작 (roomId: ${widget.roomId})');

      // 🔧 Provider 참조 안전하게 가져오기
      if (!mounted || _isDisposed) return;

      roomsProvider = context.read<RoomsProvider>();
      chatProvider = context.read<ChatProvider>();
      provider = context.read<RoomProvider>();

      // 방정보 업데이트
      isOpen = await roomsProvider.updateRoom(widget.roomId) ?? false;
      print('✅ 방 업데이트 완료 - roomId: ${widget.roomId}');

      if (_isDisposed) return;

      // 조인이 안되어있다면 조인
      if (!chatProvider.isJoined(widget.roomId)) {
        await chatProvider.joinRoom(widget.roomId);
        print('✅ 소켓에 조인됨');
      }

      if (_isDisposed) return;

      // 🔧 데이터 준비 대기 (최대 5초)
      const maxWaitTime = Duration(seconds: 5);
      const checkInterval = Duration(milliseconds: 200);
      final startTime = DateTime.now();

      while (!_isDataReady() && !_isDisposed) {
        await Future.delayed(checkInterval);

        if (DateTime.now().difference(startTime) > maxWaitTime) {
          print('⏰ 데이터 준비 타임아웃 - 현재 상태로 진행');
          break;
        }
      }

      if (_isDisposed) return;

      // 방 데이터가 없다면 프리뷰로 이동
      final myData = chatProvider.my[widget.roomId];
      print('📊 현방에서의 내 데이터: $myData');

      if (myData == null) {
        await chatProvider.removeRoom(widget.roomId);
        if (mounted && !_isDisposed) {
          context.pushReplacement('/previewRoom/${widget.roomId}');
        }
        return;
      }

      // 룸데이터 룸 프로바이더에 세팅하기
      if (provider.room == null && !_isDisposed) {
        print('🔧 프로바이더에 룸이 적용안되어 재설정 실행');
        final rooms = roomsProvider.rooms;
        final quickRooms = roomsProvider.quickRooms!;

        if (rooms != null && (rooms.containsKey(widget.roomId) || quickRooms.containsKey(widget.roomId))) {
          final initRoom = isOpen ? quickRooms[widget.roomId] : rooms[widget.roomId];
          await provider.setRoom(initRoom);
        }
      }

      if (_isDisposed) return;

      // 🔧 소켓 리스너 등록
      provider.socketListener(isOn: true);

      // 🔧 lastRead 업데이트 - 초기화 완료 후 스케줄링
      await _scheduleLastReadUpdate();
      _hasInitializedLastRead = true;

      print('✅ 방 설정 완료');

    } catch (e) {
      print('❌ 방 설정 오류: $e');
      if (mounted && !_isDisposed) {
        context.pop();
        DialogManager.errorHandler('방 정보를 불러오는데 실패했습니다');
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitializing = false;
        });
      }
      print('🔄 _isInitializing = false 설정됨');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Scaffold(
        body: Center(child: Text('페이지가 종료되었습니다')),
      );
    }

    // 🔧 안전한 Provider 참조
    try {
      roomsProvider = Provider.of<RoomsProvider>(context);
      chatProvider = Provider.of<ChatProvider>(context);
      provider = Provider.of<RoomProvider>(context);
    } catch (e) {
      print('❌ Provider 참조 오류: $e');
      return Scaffold(
        body: Center(child: Text('초기화 오류가 발생했습니다')),
      );
    }

    // 로딩 상태 처리
    if (provider.room == null || _isInitializing) {
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
                      if (provider.lastAnnounce.isNotEmpty)
                        SizedBox(height: 60.h),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollNotification) {
                            // 🔧 스크롤 시 lastRead 업데이트 스케줄링
                            if (_hasInitializedLastRead && scrollNotification is ScrollEndNotification) {
                              _scheduleLastReadUpdate();
                            }
                            return false;
                          },
                          child: ChatList(
                            roomProvider: provider,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ChatField(roomProvider: provider),
                    ],
                  ),
                  if (provider.lastAnnounce.isNotEmpty)
                    Positioned(
                        top: 0,
                        right: 0,
                        left: 0,
                        child: RoomAnnouncedWidget(announce: provider.lastAnnounce)
                    )
                ],
              )
          )
      ),
    );
  }
}