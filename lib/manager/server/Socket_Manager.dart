import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  IO.Socket? socket;
  static final SocketManager instance = SocketManager._internal();
  factory SocketManager() => instance;

  // 연결 상태
  bool _isConnecting = false;
  bool _isConnected = false;

  // 재연결 관리
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  SocketManager._internal();

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // 소켓 연결
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      print("🔗 소켓이 이미 연결 중이거나 연결되어 있습니다.");
      return;
    }

    try {
      _isConnecting = true;
      print("🚀 소켓 연결 시작");

      // 사용자 인증 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ 로그인되어 있지 않습니다. 소켓 연결을 중단합니다.");
        _isConnecting = false;
        return;
      }

      final uid = user.uid;

      // 기존 소켓 정리
      _cleanupSocket();

      // 소켓 초기화
      socket = IO.io(
          dotenv.get('SOCKET_URL'),
          IO.OptionBuilder()
              .disableAutoConnect()
              .setTransports(['websocket'])
              .setExtraHeaders({'uid': uid})
              .setAuth({'uid': uid})
              .setReconnectionDelay(1000)
              .setReconnectionAttempts(5)
              .enableReconnection()
              .build()
      );

      // 이벤트 리스너 등록
      _registerSocketEvents();

      // 연결 시작
      socket?.connect();
      print("🔗 소켓 연결 시도: ${dotenv.get('SOCKET_URL')}");
    } catch (e) {
      print("❌ 소켓 연결 초기화 오류: $e");
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // 소켓 이벤트 등록
  void _registerSocketEvents() {
    if (socket == null) return;

    // 연결 성공
    socket!.onConnect((_) {
      print("✅ 소켓 연결 성공");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();

      _handleSocketConnected();
    });

    // 재연결 성공
    socket!.onReconnect((_) {
      print("🔄 소켓 재연결 성공");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();

      _handleSocketReconnected();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      print("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;

      _handleSocketDisconnected();

      // 자동 재연결이 필요한 경우에만 수동 재연결
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // 연결 오류
    socket!.onConnectError((error) {
      print("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    });

    // 재연결 시도
    socket!.onReconnectAttempt((attemptNumber) {
      print("🔄 소켓 재연결 시도: $attemptNumber");
    });

    // 재연결 실패
    socket!.onReconnectFailed((_) {
      print("❌ 소켓 재연결 실패");
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    });
  }

  // 소켓 연결 성공 처리
  void _handleSocketConnected() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      // ChatProvider 초기화 (소켓 리스너만 설정)
      final chatProvider = context.read<ChatProvider>();
      chatProvider._setSocketListeners();
      print("✅ ChatProvider 소켓 리스너 설정 완료");
    } catch (e) {
      print("❌ 소켓 연결 후 Provider 초기화 오류: $e");
    }
  }

  // 소켓 재연결 처리
  void _handleSocketReconnected() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      // ChatProvider 재연결 처리
      final chatProvider = context.read<ChatProvider>();
      chatProvider.handleReconnection();

      // 게임 관련 처리 (필요한 경우)
      if (_isProviderAvailable<ScheduleProvider>()) {
        final scheduleProvider = context.read<ScheduleProvider>();
        if (scheduleProvider.isGameSchedule) {
          scheduleProvider.fetchGameTables();
        }
      }

      print("✅ 재연결 후 Provider 초기화 완료");
    } catch (e) {
      print("❌ 재연결 후 Provider 초기화 오류: $e");
    }
  }

  // 소켓 연결 해제 처리
  void _handleSocketDisconnected() {
    final context = AppRoute.context;
    if (context == null) return;

    try {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.onDisconnect();
      print("✅ 연결 해제 후 Provider 정리 완료");
    } catch (e) {
      print("❌ 연결 해제 후 Provider 정리 오류: $e");
    }
  }

  // 재연결 스케줄링
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print("❌ 최대 재연결 시도 횟수 초과 - 재시도를 중단합니다");

      // 30초 후 재시도 카운터 리셋
      Future.delayed(const Duration(seconds: 30), () {
        _reconnectAttempts = 0;
        print("🔄 재연결 시도 횟수 초기화됨");
      });
      return;
    }

    _cancelReconnectTimer();
    _reconnectAttempts++;

    final delay = Duration(
        seconds: _reconnectDelay.inSeconds * _reconnectAttempts
    );

    print("🔄 ${delay.inSeconds}초 후 재연결 시도 ($_reconnectAttempts/$_maxReconnectAttempts)");

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  // 재연결 타이머 취소
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 소켓 정리
  void _cleanupSocket() {
    try {
      if (socket != null) {
        socket!.disconnect();
        socket!.dispose();
        socket = null;
      }
    } catch (e) {
      print("❌ 소켓 정리 중 오류: $e");
    }
  }

  // 이벤트 리스너 등록
  void on(String event, Function(dynamic) handler) {
    if (_isConnected && socket != null) {
      socket!.on(event, handler);
    } else {
      print("⚠️ 소켓이 연결되지 않아 이벤트 리스너를 등록할 수 없습니다: $event");
    }
  }

  // 이벤트 리스너 제거
  void off(String event, [Function? handler]) {
    if (socket != null) {
      socket!.off(event);
    }
  }

  // 이벤트 전송
  void emit(String event, dynamic data) {
    if (_isConnected && socket != null) {
      socket!.emit(event, data);
    } else {
      print("⚠️ 소켓이 연결되지 않아 이벤트를 보낼 수 없습니다: $event");
    }
  }

  // 응답 확인이 필요한 이벤트 전송
  void emitWithAck(String event, dynamic data, Function handler) {
    if (_isConnected && socket != null) {
      socket!.emitWithAck(
        event,
        data,
        ack: handler,
      );
    } else {
      print("⚠️ 소켓이 연결되지 않아 Ack 이벤트를 보낼 수 없습니다: $event");
    }
  }

  // 소켓 연결 해제
  void disconnect() {
    print("🔌 소켓 연결 해제 중...");
    _cancelReconnectTimer();
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;

    try {
      socket?.disconnect();
    } catch (e) {
      print("❌ 소켓 해제 중 오류: $e");
    }
  }

  // Provider 사용 가능 여부 확인
  bool _isProviderAvailable<T>() {
    try {
      final context = AppRoute.context;
      if (context == null) return false;

      Provider.of<T>(context, listen: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 리소스 정리
  void dispose() {
    _cancelReconnectTimer();
    _cleanupSocket();
  }
}