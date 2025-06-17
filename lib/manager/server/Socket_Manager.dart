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
  Timer? _healthCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _healthCheckInterval = Duration(seconds: 30);

  // 🔧 Provider 처리 상태 관리
  bool _isProcessingReconnect = false;

  // 🔧 백그라운드 복귀 감지
  bool _isFromBackground = false;
  DateTime? _lastConnectTime;

  SocketManager._internal();

  // Getters
  bool get isConnected => _isConnected && socket?.connected == true;
  bool get isConnecting => _isConnecting;
  bool get isProcessingReconnect => _isProcessingReconnect;

  // 🔧 실제 연결 상태 확인
  bool get isReallyConnected {
    return _isConnected &&
        socket != null &&
        socket!.connected &&
        socket!.id != null;
  }

  // 소켓 연결
  Future<void> connect({bool fromBackground = false}) async {
    if (_isConnecting) {
      debugPrint("🔗 소켓 연결이 이미 진행 중입니다.");
      return;
    }

    // 🔧 이미 연결되어 있고 실제로 작동 중이면 스킵
    if (isReallyConnected && !fromBackground) {
      debugPrint("🔗 소켓이 이미 연결되어 있습니다.");
      return;
    }

    _isFromBackground = fromBackground;

    try {
      _isConnecting = true;
      debugPrint("🚀 소켓 연결 시작 ${fromBackground ? '(백그라운드 복귀)' : ''}");

      // 사용자 인증 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인되어 있지 않습니다. 소켓 연결을 중단합니다.");
        _isConnecting = false;
        return;
      }

      final uid = user.uid;

      // 🔧 백그라운드 복귀시 기존 소켓 강제 정리
      if (fromBackground) {
        await _forceCleanupSocket();
      } else {
        _cleanupSocket();
      }

      // 소켓 초기화
      socket = IO.io(
          dotenv.get('SOCKET_URL'),
          IO.OptionBuilder()
              .disableAutoConnect()
              .setTransports(['websocket'])
              .setExtraHeaders({'uid': uid})
              .setAuth({'uid': uid})
              .setReconnectionDelay(fromBackground ? 500 : 1000)
              .setReconnectionAttempts(fromBackground ? 10 : 5)
              .enableReconnection()
              .setTimeout(fromBackground ? 10000 : 20000)
              .build()
      );

      // 이벤트 리스너 등록
      _registerSocketEvents();

      // 연결 시작
      socket?.connect();
      debugPrint("🔗 소켓 연결 시도: ${dotenv.get('SOCKET_URL')}");

      // 🔧 백그라운드 복귀시 더 오래 대기
      if (fromBackground) {
        await _waitForConnection(Duration(seconds: 10));
      }

    } catch (e) {
      debugPrint("❌ 소켓 연결 초기화 오류: $e");
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // 🔧 연결 대기
  Future<void> _waitForConnection(Duration timeout) async {
    final startTime = DateTime.now();
    while (_isConnecting && !isReallyConnected) {
      if (DateTime.now().difference(startTime) > timeout) {
        debugPrint("⏰ 소켓 연결 대기 시간 초과");
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // 🔧 강제 소켓 정리 (백그라운드 복귀용)
  Future<void> _forceCleanupSocket() async {
    try {
      debugPrint("🧹 강제 소켓 정리 시작");

      if (socket != null) {
        // 모든 리스너 제거
        socket!.clearListeners();

        // 강제 연결 해제
        if (socket!.connected) {
          socket!.disconnect();
        }

        // 소켓 dispose
        socket!.dispose();
        socket = null;
      }

      // 상태 초기화
      _isConnected = false;
      _isProcessingReconnect = false;

      // 잠시 대기 (리소스 정리 시간)
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint("✅ 강제 소켓 정리 완료");
    } catch (e) {
      debugPrint("❌ 강제 소켓 정리 중 오류: $e");
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
      _reconnectAttempts = 0;
      _lastConnectTime = DateTime.now();
      _cancelReconnectTimer();
      _startHealthCheck();

      _handleSocketConnected();
    });

    // 재연결 성공
    socket!.onReconnect((_) {
      debugPrint("🔄 소켓 재연결 성공");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _lastConnectTime = DateTime.now();
      _cancelReconnectTimer();
      _startHealthCheck();

      _handleSocketReconnected();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      debugPrint("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;
      _isProcessingReconnect = false;
      _stopHealthCheck();

      _handleSocketDisconnected();

      // 자동 재연결이 필요한 경우에만 수동 재연결
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // 연결 오류
    socket!.onConnectError((error) {
      debugPrint("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;
      _isProcessingReconnect = false;
      _stopHealthCheck();
      _scheduleReconnect();
    });

    // 재연결 시도
    socket!.onReconnectAttempt((attemptNumber) {
      debugPrint("🔄 소켓 재연결 시도: $attemptNumber");
    });

    // 재연결 실패
    socket!.onReconnectFailed((_) {
      debugPrint("❌ 소켓 재연결 실패");
      _isConnected = false;
      _isConnecting = false;
      _isProcessingReconnect = false;
      _stopHealthCheck();
      _scheduleReconnect();
    });

    // 🔧 Pong 응답 처리 (연결 상태 확인용)
    socket!.on('pong', (_) {
      debugPrint("🏓 Pong 응답 수신 - 연결 상태 양호");
    });
  }

  // 🔧 헬스 체크 시작
  void _startHealthCheck() {
    _stopHealthCheck();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _checkConnectionHealth();
    });
  }

  // 🔧 헬스 체크 중지
  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  // 🔧 연결 상태 확인
  void _checkConnectionHealth() {
    if (!isReallyConnected) {
      debugPrint("💔 헬스 체크 실패 - 재연결 시도");
      connect();
      return;
    }

    try {
      // Ping 전송으로 연결 상태 확인
      socket?.emit('ping');
    } catch (e) {
      debugPrint("❌ 헬스 체크 중 오류: $e");
      connect();
    }
  }

  // 소켓 연결 성공 처리
  void _handleSocketConnected() {
    final context = AppRoute.context;
    if (context?.mounted != true) return;

    try {
      // ChatProvider 알림
      final chatProvider = context!.read<ChatProvider>();
      chatProvider.onSocketConnected();
      debugPrint("✅ ChatProvider 소켓 연결 완료");
    } catch (e) {
      debugPrint("❌ 소켓 연결 후 Provider 처리 오류: $e");
    }
  }

  // 🔧 개선된 소켓 재연결 처리
  void _handleSocketReconnected() {
    if (_isProcessingReconnect) {
      debugPrint("⚠️ 이미 재연결 처리 중 - 중복 실행 방지");
      return;
    }

    _isProcessingReconnect = true;
    debugPrint("🔄 소켓 재연결 처리 시작");

    // 🔧 비동기 처리로 변경
    _processReconnectionAsync();
  }

  // 🔧 비동기 재연결 처리
  Future<void> _processReconnectionAsync() async {
    final context = AppRoute.context;
    if (context?.mounted != true) {
      _isProcessingReconnect = false;
      return;
    }

    try {
      // 🔧 백그라운드 복귀인 경우 추가 처리
      if (_isFromBackground) {
        debugPrint("🔄 백그라운드 복귀 재연결 처리");
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // ChatProvider 재연결 처리 (비동기로 대기)
      final chatProvider = context!.read<ChatProvider>();
      await Future.microtask(() => chatProvider.onSocketReconnected());

      // 게임 관련 처리 (필요한 경우)
      if (_isProviderAvailable<ScheduleProvider>()) {
        final scheduleProvider = context.read<ScheduleProvider>();
        if (scheduleProvider.isGameSchedule) {
          await Future.microtask(() => scheduleProvider.fetchGameTables());
        }
      }

      debugPrint("✅ 소켓 재연결 처리 완료");
    } catch (e) {
      debugPrint("❌ 소켓 재연결 처리 오류: $e");
    } finally {
      _isProcessingReconnect = false;
      _isFromBackground = false;
    }
  }

  // 소켓 연결 해제 처리
  void _handleSocketDisconnected() {
    final context = AppRoute.context;
    if (context?.mounted != true) return;

    try {
      final chatProvider = context!.read<ChatProvider>();
      chatProvider.onDisconnect();
      debugPrint("✅ 연결 해제 후 Provider 정리 완료");
    } catch (e) {
      debugPrint("❌ 연결 해제 후 Provider 정리 오류: $e");
    }
  }

  // 재연결 스케줄링
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ 최대 재연결 시도 횟수 초과 - 재시도를 중단합니다");

      // 30초 후 재시도 카운터 리셋
      Future.delayed(const Duration(seconds: 30), () {
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
      if (!isReallyConnected && !_isConnecting) {
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
      debugPrint("❌ 소켓 정리 중 오류: $e");
    }
  }

  // 이벤트 리스너 등록
  void on(String event, Function(dynamic) handler) {
    if (isReallyConnected && socket != null) {
      socket!.on(event, handler);
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 이벤트 리스너를 등록할 수 없습니다: $event");
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
    if (isReallyConnected && socket != null) {
      socket!.emit(event, data);
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 이벤트를 보낼 수 없습니다: $event");
    }
  }

  // 응답 확인이 필요한 이벤트 전송
  void emitWithAck(String event, dynamic data, Function handler) {
    if (isReallyConnected && socket != null) {
      socket!.emitWithAck(
        event,
        data,
        ack: handler,
      );
    } else {
      debugPrint("⚠️ 소켓이 연결되지 않아 Ack 이벤트를 보낼 수 없습니다: $event");
    }
  }

  // 소켓 연결 해제
  void disconnect() {
    debugPrint("🔌 소켓 연결 해제 중...");
    _cancelReconnectTimer();
    _stopHealthCheck();
    _isConnected = false;
    _isConnecting = false;
    _isProcessingReconnect = false;
    _reconnectAttempts = 0;
    _isFromBackground = false;

    try {
      socket?.disconnect();
    } catch (e) {
      debugPrint("❌ 소켓 해제 중 오류: $e");
    }
  }

  // Provider 사용 가능 여부 확인
  bool _isProviderAvailable<T>() {
    try {
      final context = AppRoute.context;
      if (context?.mounted != true) return false;

      Provider.of<T>(context!, listen: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 리소스 정리
  void dispose() {
    _cancelReconnectTimer();
    _stopHealthCheck();
    _cleanupSocket();
    _isProcessingReconnect = false;
    _isFromBackground = false;
  }
}