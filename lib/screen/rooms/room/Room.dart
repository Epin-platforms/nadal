import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
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

  // Core providers - late initialization for safety
  late RoomsProvider _roomsProvider;
  late ChatProvider _chatProvider;
  late RoomProvider _roomProvider;

  // State management - simplified and safer
  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _hasInitializedLastRead = false;
  bool _needsLastReadUpdate = false;
  late final bool _isOpen;

  // 🔧 백그라운드 복귀 관리 (간단화)
  bool _isScreenActive = true;

  // Timer management
  Timer? _lastReadUpdateTimer;

  // Constants for better maintainability
  static const Duration _lastReadDebounceDelay = Duration(milliseconds: 500);
  static const Duration _dataWaitTimeout = Duration(seconds: 5);
  static const Duration _dataCheckInterval = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use addPostFrameCallback for safer initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _initializeRoom();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup in reverse order of initialization
    _cancelLastReadTimer();

    // Safe provider cleanup
    try {
      if (_hasInitializedLastRead) {
        _performLastReadUpdate();
      }

      _roomProvider.socketListener(isOn: false);
      _chatProvider.readReset(widget.roomId);
    } catch (e) {
      debugPrint('❌ 정리 작업 오류: $e');
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed) return;

    final previousState = _isScreenActive;
    _isScreenActive = state == AppLifecycleState.resumed;

    debugPrint("🔄 Room 화면 생명주기 변경: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        if (!previousState) {
          _handleAppResumed();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      default:
        break;
    }
  }

  // 🔧 백그라운드 이동 처리 (간단화)
  void _handleAppPaused() {
    if (_isDisposed) return;

    debugPrint("🔄 Room 화면 - 백그라운드 이동");

    // lastRead 업데이트
    if (_hasInitializedLastRead) {
      _performLastReadUpdate();
    }
  }

  // 🔧 백그라운드 복귀 처리 (간단화)
  Future<void> _handleAppResumed() async {
    if (_isDisposed) return;

    debugPrint("🔄 Room 화면 - 백그라운드 복귀 처리");

    try {
      // 🔧 소켓 재연결은 SocketManager와 AppProvider에서 자동 처리됨
      // 여기서는 현재 방의 lastRead만 업데이트
      _roomProvider.socketListener(isOn: true);
      await _scheduleLastReadUpdate();

      debugPrint("✅ Room 화면 백그라운드 복귀 처리 완료");
    } catch (e) {
      debugPrint("❌ Room 화면 백그라운드 복귀 처리 실패: $e");
    }
  }

  // Initialize room with proper error handling and sequential processing
  Future<void> _initializeRoom() async {
    if (_isDisposed || !mounted) return;
    // Validate room ID first
    if (widget.roomId <= 0) {
      _handleInitializationError('올바른 접근이 아닙니다');
      return;
    }

    final notification = context.read<NotificationProvider>();
    _setInitializingState(true);

    try {
      await _processRoomInitialization();
    } catch (e) {
      debugPrint('❌ 방 초기화 오류: $e');
      _handleInitializationError('방 정보를 불러오는데 실패했습니다');
    } finally {
      _setInitializingState(false);
      notification.clearRoomNotifications(widget.roomId);
    }
  }

  // Core room initialization process
  Future<void> _processRoomInitialization() async {
    if (_isDisposed) return;

    debugPrint('🚀 방 설정 시작 (roomId: ${widget.roomId})');

    // Step 1: Initialize providers safely
    _initializeProviders();

    // Step 2: Update room information
    _isOpen = await _roomsProvider.updateRoom(widget.roomId) ?? false;
    debugPrint('✅ 방 업데이트 완료 - roomId: ${widget.roomId}');

    if (_isDisposed) return;

    // Step 3: Join room if not already joined
    await _ensureRoomJoined();

    if (_isDisposed) return;

    // Step 4: Wait for data to be ready
    await _waitForDataReady();

    if (_isDisposed) return;

    // Step 5: Validate user data
    if (!await _validateUserData()) return;

    // Step 6: Configure room provider
    await _configureRoomProvider();

    if (_isDisposed) return;

    // Step 7: Enable socket listener
    _roomProvider.socketListener(isOn: true);

    // Step 8: Set lastRead system as initialized
    _hasInitializedLastRead = true;

    // Step 9: Schedule initial lastRead update
    await _scheduleLastReadUpdate();

    debugPrint('✅ 방 설정 완료');
  }

  // Initialize providers with error handling
  void _initializeProviders() {
    if (!mounted || _isDisposed) return;

    _roomsProvider = context.read<RoomsProvider>();
    _chatProvider = context.read<ChatProvider>();
    _roomProvider = context.read<RoomProvider>();
  }

  // Ensure user is joined to the room
  Future<void> _ensureRoomJoined() async {
    if (_isDisposed) return;

    if (!_chatProvider.isJoined(widget.roomId)) {
      await _chatProvider.joinRoom(widget.roomId);
      debugPrint('✅ 소켓에 조인됨');
    }
  }

  // Wait for essential data to be ready with timeout
  Future<void> _waitForDataReady() async {
    if (_isDisposed) return;

    final startTime = DateTime.now();

    while (!_isDataReady() && !_isDisposed) {
      await Future.delayed(_dataCheckInterval);

      if (DateTime.now().difference(startTime) > _dataWaitTimeout) {
        debugPrint('⏰ 데이터 준비 타임아웃 - 현재 상태로 진행');
        break;
      }
    }
  }

  // Validate user data and handle redirect if needed
  Future<bool> _validateUserData() async {
    if (_isDisposed) return false;

    final myData = _chatProvider.my[widget.roomId];
    debugPrint('📊 현방에서의 내 데이터: $myData');

    if (myData == null) {
      await _chatProvider.removeRoom(widget.roomId);
      if (mounted && !_isDisposed) {
        context.pushReplacement('/previewRoom/${widget.roomId}');
      }
      return false;
    }

    return true;
  }

  // Configure room provider if needed
  Future<void> _configureRoomProvider() async {
    if (_isDisposed) return;

    if (_roomProvider.room == null) {
      debugPrint('🔧 프로바이더에 룸이 적용안되어 재설정 실행');

      final rooms = _roomsProvider.rooms;
      final quickRooms = _roomsProvider.quickRooms;

      if (rooms != null && quickRooms != null) {
        final roomExists = rooms.containsKey(widget.roomId) ||
            quickRooms.containsKey(widget.roomId);

        if (roomExists) {
          final initRoom = _isOpen
              ? quickRooms[widget.roomId]
              : rooms[widget.roomId];
          await _roomProvider.setRoom(initRoom);
        }
      }
    }
  }

  // Check if essential data is ready
  bool _isDataReady() {
    try {
      final myData = _chatProvider.my[widget.roomId];
      final chats = _chatProvider.chat[widget.roomId];
      final isJoined = _chatProvider.isJoined(widget.roomId);

      return myData != null && chats != null && isJoined;
    } catch (e) {
      debugPrint('❌ 데이터 준비 상태 확인 오류: $e');
      return false;
    }
  }

  // Schedule lastRead update with debouncing
  Future<void> _scheduleLastReadUpdate() async {
    if (_isDisposed || !_hasInitializedLastRead) return;

    _needsLastReadUpdate = true;
    _cancelLastReadTimer();

    _lastReadUpdateTimer = Timer(_lastReadDebounceDelay, () {
      if (!_isDisposed && _needsLastReadUpdate) {
        _performLastReadUpdate();
        _needsLastReadUpdate = false;
      }
    });
  }

  // Cancel pending lastRead timer
  void _cancelLastReadTimer() {
    _lastReadUpdateTimer?.cancel();
    _lastReadUpdateTimer = null;
  }

  // Perform lastRead update safely
  void _performLastReadUpdate() {
    if (_isDisposed) return;

    try {
      _chatProvider.updateLastRead(widget.roomId);
      debugPrint('✅ lastRead 업데이트 완료');
    } catch (e) {
      debugPrint('❌ lastRead 업데이트 오류: $e');
    }
  }

  // Handle initialization errors
  void _handleInitializationError(String message) {
    if (mounted && !_isDisposed) {
      context.pop();
      DialogManager.errorHandler(message);
    }
  }

  // Set initializing state safely
  void _setInitializingState(bool value) {
    if (mounted && !_isDisposed && _isInitializing != value) {
      setState(() {
        _isInitializing = value;
      });
    }
  }

  // Safe provider access
  T? _safeProviderAccess<T>(T Function() accessor) {
    try {
      return accessor();
    } catch (e) {
      debugPrint('❌ Provider 접근 오류: $e');
      return null;
    }
  }

  // 🔧 연결 상태 위젯 (간단화)
  Widget _buildConnectionStatus() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.socketLoading) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          color: Colors.orange.withValues(alpha:0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '연결 중...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Scaffold(
        body: Center(
          child: Text(
            '페이지가 종료되었습니다',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      );
    }

    // Safe provider access
    final roomsProvider = _safeProviderAccess(() => Provider.of<RoomsProvider>(context));
    final chatProvider = _safeProviderAccess(() => Provider.of<ChatProvider>(context));
    final roomProvider = _safeProviderAccess(() => Provider.of<RoomProvider>(context));

    if (roomsProvider == null || chatProvider == null || roomProvider == null) {
      return Scaffold(
        body: Center(
          child: Text(
            '초기화 오류가 발생했습니다',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      );
    }

    // Update local references
    _roomsProvider = roomsProvider;
    _chatProvider = chatProvider;
    _roomProvider = roomProvider;

    // Show loading state
    if (roomProvider.room == null || _isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NadalCircular(),
              SizedBox(height: 16.h),
              Text(
                '채팅방을 불러오는 중...',
                style: TextStyle(fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    final roomName = roomProvider.room?['roomName']?.toString() ?? '채팅방';
    final hasAnnouncement = roomProvider.lastAnnounce.isNotEmpty;

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
                  // 🔧 연결 상태 표시
                  _buildConnectionStatus(),

                  if (hasAnnouncement) SizedBox(height: 60.h),

                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (_hasInitializedLastRead &&
                            scrollNotification is ScrollEndNotification &&
                            _isScreenActive) {
                          _scheduleLastReadUpdate();
                        }
                        return false;
                      },
                      child: ChatList(
                        roomProvider: roomProvider,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if(context.read<UserProvider>().canCommunity())
                  ChatField(roomProvider: roomProvider)
                  else
                    SizedBox(
                      height: 40.h,
                      child: Center(
                        child: Text('이용 규칙 미준수로 채팅을 이용할 수 없어요', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).hintColor),),
                      ),
                    )
                ],
              ),
              if (hasAnnouncement)
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: RoomAnnouncedWidget(
                    announce: roomProvider.lastAnnounce,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}