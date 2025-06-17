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

  // 재연결 관리
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _healthCheckInterval = Duration(seconds: 30);

  // 🔧 백그라운드 관리 개선
  bool _isInBackground = false;
  bool _needsReconnectOnResume = false;

  // 🔧 **추가: 리스너 등록 완료 상태 관리**
  bool _listenersRegistered = false;
  final List<Function()> _pendingListenerRegistrations = [];

  SocketManager._internal();

  // Getters
  bool get isConnected => _isConnected && socket?.connected == true;
  bool get isConnecting => _isConnecting;
  bool get isInBackground => _isInBackground;

  // 🔧 실제 연결 상태 확인
  bool get isReallyConnected {
    return _isConnected &&
        socket != null &&
        socket!.connected &&
        socket!.id != null;
  }

  // 🔧 **추가: 리스너 등록 가능 상태 확인**
  bool get isReadyForListeners {
    return isReallyConnected && _listenersRegistered;
  }

  // 🔧 백그라운드 상태 설정
  void setBackgroundState(bool inBackground) {
    if (_isInBackground == inBackground) return;

    _isInBackground = inBackground;

    if (inBackground) {
      debugPrint("📱 앱이 백그라운드로 이동");
    } else {
      debugPrint("📱 앱이 포그라운드로 복귀 - 무조건 재연결 필요");
      _needsReconnectOnResume = true;
      _executeBackgroundReconnect();
    }
  }

  // 🔧 백그라운드 재연결 실행
  Future<void> _executeBackgroundReconnect() async {
    if (!_needsReconnectOnResume) return;

    try {
      debugPrint("🔌 백그라운드 복귀 재연결 시작");
      _needsReconnectOnResume = false;

      // 기존 소켓 완전히 정리
      await _forceCleanupSocket();

      // 새로운 연결 시작
      await connect(fromBackground: true);

    } catch (e) {
      debugPrint("❌ 백그라운드 재연결 실패: $e");
      _scheduleReconnect();
    }
  }

  // 소켓 연결
  Future<void> connect({bool fromBackground = false}) async {
    if (_isConnecting) {
      debugPrint("🔗 소켓 연결이 이미 진행 중입니다.");
      return;
    }

    if (!fromBackground && isReallyConnected) {
      debugPrint("🔗 소켓이 이미 연결되어 있습니다.");
      return;
    }

    try {
      _isConnecting = true;
      debugPrint("🚀 소켓 연결 시작 ${fromBackground ? '(백그라운드 복귀)' : ''}");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인되어 있지 않습니다. 소켓 연결을 중단합니다.");
        _isConnecting = false;
        return;
      }

      final uid = user.uid;

      // 기존 소켓 정리
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
              .setReconnectionDelay(500)
              .setReconnectionAttempts(fromBackground ? 10 : 5)
              .enableReconnection()
              .setTimeout(fromBackground ? 15000 : 20000)
              .build()
      );

      // 이벤트 리스너 등록
      _registerSocketEvents();

      // 연결 시작
      socket?.connect();
      debugPrint("🔗 소켓 연결 시도: ${dotenv.get('SOCKET_URL')}");

      // 백그라운드 복귀시 더 오래 대기
      if (fromBackground) {
        await _waitForConnection(Duration(seconds: 15));
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

  // 🔧 강제 소켓 정리
  Future<void> _forceCleanupSocket() async {
    try {
      debugPrint("🧹 강제 소켓 정리 시작");

      // **수정: 리스너 상태 초기화**
      _listenersRegistered = false;
      _pendingListenerRegistrations.clear();

      if (socket != null) {
        socket!.clearListeners();
        if (socket!.connected) {
          socket!.disconnect();
        }
        socket!.dispose();
        socket = null;
      }

      _isConnected = false;
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
      _cancelReconnectTimer();
      _startHealthCheck();

      _handleSocketReconnected();
    });

    // 연결 종료
    socket!.onDisconnect((reason) {
      debugPrint("❌ 소켓 연결 종료: $reason");
      _isConnected = false;
      _isConnecting = false;
      _listenersRegistered = false; // **추가**
      _stopHealthCheck();

      _handleSocketDisconnected();

      if (reason != 'io client disconnect' && !_isInBackground) {
        _scheduleReconnect();
      }
    });

    // 연결 오류
    socket!.onConnectError((error) {
      debugPrint("❌ 소켓 연결 오류: $error");
      _isConnected = false;
      _isConnecting = false;
      _listenersRegistered = false; // **추가**
      _stopHealthCheck();

      if (!_isInBackground) {
        _scheduleReconnect();
      }
    });

    socket!.onReconnectAttempt((attemptNumber) {
      debugPrint("🔄 소켓 재연결 시도: $attemptNumber");
    });

    socket!.onReconnectFailed((_) {
      debugPrint("❌ 소켓 재연결 실패");
      _isConnected = false;
      _isConnecting = false;
      _listenersRegistered = false; // **추가**
      _stopHealthCheck();

      if (!_isInBackground) {
        _scheduleReconnect();
      }
    });

    socket!.on('pong', (_) {
      debugPrint("🏓 Pong 응답 수신 - 연결 상태 양호");
    });
  }

  // 헬스 체크 시작
  void _startHealthCheck() {
    if (_isInBackground) return;

    _stopHealthCheck();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      if (!_isInBackground) {
        _checkConnectionHealth();
      }
    });
  }

  // 헬스 체크 중지
  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  // 연결 상태 확인
  void _checkConnectionHealth() {
    if (_isInBackground) return;

    if (!isReallyConnected) {
      debugPrint("💔 헬스 체크 실패 - 재연결 시도");
      connect();
      return;
    }

    try {
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
      final chatProvider = context!.read<ChatProvider>();
      chatProvider.onSocketConnected();

      // **수정: 리스너 등록을 안전하게 처리**
      _registerProvidersListenersSequentially();

      debugPrint("✅ ChatProvider 소켓 연결 완료");
    } catch (e) {
      debugPrint("❌ 소켓 연결 후 Provider 처리 오류: $e");
    }
  }

  // 소켓 재연결 처리
  void _handleSocketReconnected() {
    final context = AppRoute.context;
    if (context?.mounted != true) return;

    try {
      debugPrint("🔄 소켓 재연결 처리 시작");

      // ChatProvider 재연결 처리
      final chatProvider = context!.read<ChatProvider>();
      chatProvider.onSocketReconnected();

      // **수정: 순차적으로 리스너 재등록**
      _registerProvidersListenersSequentially();

      debugPrint("✅ 소켓 재연결 처리 완료");
    } catch (e) {
      debugPrint("❌ 소켓 재연결 처리 오류: $e");
    }
  }

  // **추가: Provider 리스너들을 순차적으로 등록**
  Future<void> _registerProvidersListenersSequentially() async {
    if (!isReallyConnected) {
      debugPrint("❌ 소켓이 준비되지 않아 리스너 등록 지연");
      return;
    }

    try {
      final context = AppRoute.context;
      if (context?.mounted != true) return;

      debugPrint("🔧 Provider 리스너 순차 등록 시작");

      // 1. ChatProvider 리스너 등록
      final chatProvider = context!.read<ChatProvider>();
      await chatProvider.registerSocketListenersSafely();

      // 2. RoomProvider 리스너 등록 (있다면)
      try {
        final roomProvider = context.read<RoomProvider>();
        roomProvider.reattachSocketListeners();
        debugPrint("✅ RoomProvider 소켓 리스너 재설정 완료");
      } catch (e) {
        debugPrint("⚠️ RoomProvider가 없거나 오류: $e");
      }

      _listenersRegistered = true;
      debugPrint("✅ 모든 Provider 리스너 등록 완료");

      // 대기 중인 리스너 등록 실행
      _processPendingListenerRegistrations();

    } catch (e) {
      debugPrint("❌ Provider 리스너 등록 실패: $e");
      // 3초 후 재시도
      Timer(const Duration(seconds: 3), () {
        if (isReallyConnected && !_listenersRegistered) {
          _registerProvidersListenersSequentially();
        }
      });
    }
  }

  // **추가: 대기 중인 리스너 등록 처리**
  void _processPendingListenerRegistrations() {
    if (_pendingListenerRegistrations.isNotEmpty) {
      debugPrint("🔧 대기 중인 리스너 ${_pendingListenerRegistrations.length}개 등록");
      final pending = List.from(_pendingListenerRegistrations);
      _pendingListenerRegistrations.clear();

      for (final registration in pending) {
        try {
          registration();
        } catch (e) {
          debugPrint("❌ 대기 리스너 등록 실패: $e");
        }
      }
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
    if (_isInBackground) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("❌ 최대 재연결 시도 횟수 초과 - 재시도를 중단합니다");

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
      if (!isReallyConnected && !_isConnecting && !_isInBackground) {
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
      _listenersRegistered = false; // **추가**
    } catch (e) {
      debugPrint("❌ 소켓 정리 중 오류: $e");
    }
  }

  // **수정: 안전한 이벤트 리스너 등록**
  void on(String event, Function(dynamic) handler) {
    if (isReallyConnected && socket != null) {
      socket!.on(event, handler);
      debugPrint("✅ 리스너 등록 성공: $event");
    } else {
      debugPrint("⚠️ 소켓이 준비되지 않음 - 리스너 대기열에 추가: $event");
      _pendingListenerRegistrations.add(() {
        if (isReallyConnected && socket != null) {
          socket!.on(event, handler);
          debugPrint("✅ 대기열에서 리스너 등록: $event");
        }
      });
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
    _listenersRegistered = false; // **추가**
    _reconnectAttempts = 0;
    _needsReconnectOnResume = false;

    try {
      socket?.disconnect();
    } catch (e) {
      debugPrint("❌ 소켓 해제 중 오류: $e");
    }
  }

  // 리소스 정리
  void dispose() {
    _cancelReconnectTimer();
    _stopHealthCheck();
    _cleanupSocket();
    _needsReconnectOnResume = false;
    _pendingListenerRegistrations.clear(); // **추가**
  }
}