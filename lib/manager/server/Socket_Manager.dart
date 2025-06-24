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

  // 🔧 핑퐁 관련 속성
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  static const Duration _pingInterval = Duration(seconds: 25); // 25초마다 핑
  static const Duration _pongTimeout = Duration(seconds: 10); // 퐁 응답 대기 시간
  bool _waitingForPong = false;

  SocketManager._internal();

  // Getters
  bool get isConnected => _isConnected && socket?.connected == true;
  bool get isConnecting => _isConnecting;

  // 🔧 연결끊김
  void setConnected(bool isConnected) {
    if (_isConnected == isConnected) return;
    if (isConnected){
      debugPrint("📱 앱이 소켓과 연결됨");
      _reconnectTimer?.cancel(); // 이전 타이머 제거
      _reconnectTimer = Timer(const Duration(milliseconds: 300), () {
        debugPrint("📱 소켓 연결 체크");
        if (socket?.disconnected ?? true) {
          debugPrint("📱 연결이 끊겨있어 다시 연결합니다");
          connect();
        }else{
          debugPrint("📱 소켓이 연결되어있습니다");
        }
      });
    } else {
      _isConnected = isConnected;
      _reconnectTimer?.cancel(); // 끊길 때도 타이머 정리
      debugPrint("📱 앱이 소켓과 연결이 종료됨");
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
      _isConnected = true;
    } catch (e) {
      debugPrint("❌ 소켓 연결 초기화 오류: $e");
      _isConnecting = false;
    }
  }

  // 🚀 핑퐁 시작
  void _startPingPong() {
    _stopPingPong(); // 기존 타이머 정리

    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (socket?.connected == true && !_waitingForPong) {
        _sendPing();
      }
    });

    debugPrint("🏓 핑퐁 시작");
  }

  // 🛑 핑퐁 중지
  void _stopPingPong() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _waitingForPong = false;
    debugPrint("🛑 핑퐁 중지");
  }

  // 📤 핑 전송
  void _sendPing() {
    if (socket?.connected != true) return;

    _waitingForPong = true;
    socket!.emit('ping', DateTime.now().millisecondsSinceEpoch);
    debugPrint("🏓 핑 전송");

    // 퐁 응답 대기 타이머
    _pongTimeoutTimer = Timer(_pongTimeout, () {
      if (_waitingForPong) {
        debugPrint("❌ 퐁 응답 없음 - 연결 재시도");
        _handlePongTimeout();
      }
    });
  }

  // 📥 퐁 응답 처리
  void _handlePong(dynamic data) {
    _waitingForPong = false;
    _pongTimeoutTimer?.cancel();

    if (data is int) {
      final latency = DateTime.now().millisecondsSinceEpoch - data;
      debugPrint("🏓 퐁 수신 - 지연시간: ${latency}ms");
    } else {
      debugPrint("🏓 퐁 수신");
    }
  }

  // ⚠️ 퐁 타임아웃 처리
  void _handlePongTimeout() {
    _waitingForPong = false;
    _stopPingPong();

    // 소켓 재연결 시도
    if (socket?.connected == true) {
      debugPrint("🔄 핑퐁 타임아웃으로 인한 소켓 재연결");
      socket?.disconnect();
      socket?.connect();
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

      // 🚀 핑퐁 시작
      _startPingPong();

      _handleSocketConnected();
    });

    // 재연결 성공
    socket!.onReconnect((_) {
      debugPrint("🔄 소켓 재연결 성공");
      _isConnected = true;
      _isConnecting = false;

      // 🚀 핑퐁 시작
      _startPingPong();

      _handleSocketReconnected();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      debugPrint("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;

      // 🛑 핑퐁 중지
      _stopPingPong();
    });

    // 연결 오류
    socket!.onConnectError((error) {
      debugPrint("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;

      // 🛑 핑퐁 중지
      _stopPingPong();
    });

    // 🏓 퐁 이벤트 리스너
    socket!.on('pong', _handlePong);
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
      _stopPingPong(); // 🛑 핑퐁 중지
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {
      // 에러 무시
    }
  }

  // 리소스 정리
  void dispose() {
    _stopPingPong(); // 🛑 핑퐁 중지
    _reconnectTimer?.cancel();
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