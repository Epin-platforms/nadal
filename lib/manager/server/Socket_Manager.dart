import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../provider/room/Room_Provider.dart';

class SocketManager {
  IO.Socket? socket;
  static final SocketManager instance = SocketManager._internal();
  factory SocketManager() => instance;

  // 연결 상태
  bool _isConnecting = false;
  bool _isConnected = false;

  SocketManager._internal();

  // Getters
  bool get isConnected => _isConnected && socket?.connected == true;
  bool get isConnecting => _isConnecting;


  // 🔧 연결끊김
  void setConnected(bool isConnected) {
    if (_isConnected == isConnected) return;

    _isConnected = isConnected;

    if (isConnected) {
      debugPrint("📱 앱이 소켓과 연결이 종료됨");
    } else {
      debugPrint("📱 앱이 소켓과 연결됨");
    }
  }

  // 소켓 연결
  Future<void> connect() async {
    if (_isConnecting) {
      debugPrint("🔗 소켓 연결이 이미 진행 중입니다.");
      return;
    }

    if (_isConnected) {
      debugPrint("🔗 소켓이 이미 연결되어 있습니다.");
      return;
    }

    try {
      _isConnecting = true;
      debugPrint("🚀 소켓 연결 시작");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인되어 있지 않습니다. 소켓 연결을 중단합니다.");
        _isConnecting = false;
        return;
      }

      final uid = user.uid;

      // 소켓 초기화
      socket = IO.io(
          dotenv.get('SOCKET_URL'),
          IO.OptionBuilder()
              .disableAutoConnect()
              .setTransports(['websocket'])
              .setExtraHeaders({'uid': uid})
              .setAuth({'uid': uid})
              .setReconnectionDelay(500)
              .enableReconnection()
              .setTimeout(20000)
              .build()
      );

      // 이벤트 리스너 등록
      _registerSocketEvents();

      // 연결 시작
      socket?.connect();
      debugPrint("🔗 소켓 연결 시도: ${dotenv.get('SOCKET_URL')}");

    } catch (e) {
      debugPrint("❌ 소켓 연결 초기화 오류: $e");
      _isConnecting = false;
    }
  }

  // 소켓 이벤트 등록
  void _registerSocketEvents() {
    if (socket == null) return;

    // 연결 성공
    socket!.onConnect((_) {
      debugPrint("✅ 소켓 연결 성공");
      _isConnected = true;
      _isConnecting = false;

      _handleSocketConnected();
    });

    // 재연결 성공
    socket!.onReconnect((_) {
      debugPrint("🔄 소켓 재연결 성공");
      _isConnected = true;
      _isConnecting = false;

      _handleSocketReconnected();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      debugPrint("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;
    });

    // 연결 오류
    socket!.onConnectError((error) {
      debugPrint("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;
    });
  }


  // 소켓 연결 성공 처리
  void _handleSocketConnected() {
    final context = AppRoute.context;
    if (context?.mounted != true) return;

    try {
      final chatProvider = context!.read<ChatProvider>();
      chatProvider.onSocketConnected();
      debugPrint("✅ ChatProvider 소켓 연결 완료");
    } catch (e) {
      debugPrint("❌ 소켓 연결 후 Provider 처리 오류: $e");
    }
  }

  // 소켓 재연결 처리
  Future<void> _handleSocketReconnected() async{
    final context = AppRoute.context;
    if (context?.mounted != true) return;

    try {
      debugPrint("🔄 소켓 재연결 처리 시작");

      // 🔧 **수정: 챗 프로바이더는 최상위에서 항상 존재
      final chatProvider = context!.read<ChatProvider>();
      await chatProvider.onSocketReconnected(); //채팅 부터 차례대로 리프레쉬

      if(isCreated<RoomProvider>()){ //방 프로바이더가 존재한다면
        final roomProvider = context.read<RoomProvider>();
        await roomProvider.reconnectSocket();
      }

      if(isCreated<ScheduleProvider>()){
        final scheduleProvider = context.read<ScheduleProvider>();
        if(scheduleProvider.isGameSchedule){
         await scheduleProvider.reconnectSocket();
        }
      }

      debugPrint("✅ 소켓 재연결 처리 완료");
    } catch (e) {
      debugPrint("❌ 소켓 재연결 처리 오류: $e");
    }
  }

  /// 리스너 등록
  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  // 이벤트 리스너 제거
  void off(String event, [Function? handler]) {
    if (socket != null) {
      socket!.off(event);
    }
  }

  // 이벤트 전송
  void emit(String event, dynamic data) {
    socket!.emit(event, data);
  }

  /// 소켓 정리
  void _disposeSocket() {
    try {
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {

    }
  }

  // 리소스 정리
  void dispose() {
    _disposeSocket();
  }

  /// ChangeNotifierProvider 생성 여부 확인 (Provider가 위젯 트리에 존재하는지)
  static bool isCreated<T>() {
    try {
      final ctx = AppRoute.context;
      if(ctx == null) return false;
      Provider.of<T>(ctx, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }

}