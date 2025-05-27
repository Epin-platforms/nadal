import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  IO.Socket? socket;
  static final SocketManager instance = SocketManager._internal();
  factory SocketManager() => instance;

  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  SocketManager._internal();

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      debugPrint("소켓이 이미 연결 중이거나 연결되어 있습니다.");
      return;
    }

    try {
      _isConnecting = true;

      // 현재 사용자의 UID만 가져옵니다
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("로그인되어 있지 않습니다. 소켓 연결을 시도하지 않습니다.");
        _isConnecting = false;
        return;
      }

      final uid = user.uid;

      // 기존 소켓이 있다면 정리
      _cleanupSocket();

      // 소켓 초기화 - auth에 직접 uid 전달
      socket = IO.io(
          dotenv.get('SOCKET_URL'),
          IO.OptionBuilder()
              .disableAutoConnect() // 자동 연결 방지
              .setTransports(['websocket'])
          // HTTP 헤더로 UID 전달 (방법 1)
              .setExtraHeaders({'uid': uid})
          // Auth 데이터로 UID 전달 (방법 2)
              .setAuth({'uid': uid})
              .setReconnectionDelay(1000) // 재연결 지연 시간 (밀리초)
              .setReconnectionAttempts(5) // 최대 재연결 시도 횟수
              .enableReconnection() // 파라미터 없이 재연결 활성화
              .build()
      );

      // 연결 이벤트 등록
      _registerSocketEvents();

      // 소켓 연결 시작
      socket?.connect();
      debugPrint("소켓 연결을 시작합니다: ${dotenv.get('SOCKET_URL')}");
    } catch (e) {
      debugPrint("소켓 연결 초기화 중 오류 발생: $e");
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // 소켓 이벤트 핸들러 등록
  void _registerSocketEvents() {
    if (socket == null) return;

    // 최초 연결 성공
    socket!.onConnect((_) {
      debugPrint("✅ 소켓 연결 성공");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();

      // Provider 초기화 및 리스너 설정
      _initializeProviders();
    });

    // 재연결 성공
    socket!.onReconnect((_) {
      debugPrint("🔄 소켓 재연결 성공");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();

      // Provider 재초기화
      _handleReconnection();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      debugPrint("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;

      // Provider 정리
      _handleDisconnection();

      // 자동 재연결이 비활성화된 경우에만 수동 재연결 시도
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // 연결 오류
    socket!.onConnectError((error) {
      debugPrint("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    });

    // 재연결 시도 이벤트
    socket!.onReconnectAttempt((attemptNumber) {
      debugPrint("🔄 소켓 재연결 시도: $attemptNumber");
    });

    // 재연결 실패 이벤트
    socket!.onReconnectFailed((_) {
      debugPrint("❌ 소켓 재연결 실패");
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    });
  }

  void _initializeProviders() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setSocketListeners();
      chatProvider.initChatProvider();
      debugPrint("✅ ChatProvider 초기화 완료");
    } catch (e) {
      debugPrint("❌ Provider 초기화 오류: $e");
    }
  }

  void _handleReconnection() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      context.read<ChatProvider>().onReconnect();

      // 통합된 ScheduleProvider로 게임 관련 처리
      if (_isProviderAvailable<ScheduleProvider>()) {
        final scheduleProvider = context.read<ScheduleProvider>();
        if (scheduleProvider.isGameSchedule) {
          // 게임 관련 소켓 리스너 재설정은 ScheduleProvider 내부에서 처리됨
          scheduleProvider.fetchGameTables();
        }
      }
      debugPrint("✅ 재연결 후 Provider 초기화 완료");
    } catch (e) {
      debugPrint("❌ 재연결 후 Provider 초기화 오류: $e");
    }
  }

  void _handleDisconnection() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      context.read<ChatProvider>().onDisconnect();
      debugPrint("✅ 연결 해제 후 Provider 정리 완료");
    } catch (e) {
      debugPrint("❌ 연결 해제 후 Provider 정리 오류: $e");
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ 최대 재연결 시도 횟수 초과 - 재시도를 중단합니다");
      // 재연결 시도 초기화 (앱이 다시 활성화될 때 재시도 가능하도록)
      Future.delayed(Duration(seconds: 30), () {
        _reconnectAttempts = 0;
        debugPrint("🔄 재연결 시도 횟수 초기화됨");
      });
      return;
    }

    _cancelReconnectTimer();
    _reconnectAttempts++;

    final delay = Duration(
        seconds: _reconnectDelay.inSeconds * _reconnectAttempts
    );

    debugPrint("🔄 ${delay.inSeconds}초 후 재연결 시도 ($_reconnectAttempts/$_maxReconnectAttempts)");

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cleanupSocket() {
    try {
      if (socket != null) {
        socket!.disconnect();
        socket!.dispose();
        socket = null;
      }
    } catch (e) {
      debugPrint("소켓 정리 중 오류: $e");
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (_isConnected && socket != null) {
      socket!.on(event, handler);
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 이벤트 리스너를 등록할 수 없습니다: $event");
    }
  }

  void off(String event, [Function? handler]) {
    if (socket != null) {
      socket!.off(event);
    }
  }

  void emit(String event, dynamic data) {
    if (_isConnected && socket != null) {
      socket!.emit(event, data);
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 이벤트를 보낼 수 없습니다: $event");
    }
  }

  void disconnect() {
    debugPrint("🔌 소켓 연결 해제 중...");
    _cancelReconnectTimer();
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;

    try {
      socket?.disconnect();
    } catch (e) {
      debugPrint("소켓 해제 중 오류: $e");
    }
  }

  /// 서버에 이벤트를 보내고, 응답(Ack)을 handler에서 처리
  void emitWithAck(String event, dynamic data, Function handler) {
    if (_isConnected && socket != null) {
      socket!.emitWithAck(
        event,
        data,
        ack: handler, // 네임드 파라미터로 넘겨야 합니다
      );
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 Ack 이벤트를 보낼 수 없습니다: $event");
    }
  }

  bool _isProviderAvailable<T>() {
    try {
      final context = AppRoute.context;

      if (context == null) {
        return false;
      }
      Provider.of<T>(context, listen: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 앱 종료 시 정리
  void dispose() {
    _cancelReconnectTimer();
    _cleanupSocket();
  }
}