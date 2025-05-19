import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class SocketManager{
  late final IO.Socket socket;
  static final SocketManager instance = SocketManager._internal();
  factory SocketManager() => instance;

  SocketManager._internal();

  Future<void> connect() async {
    try {
      // 현재 사용자의 UID만 가져옵니다
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("로그인되어 있지 않습니다. 소켓 연결을 시도하지 않습니다.");
        return;
      }

      final uid = user.uid;

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
      socket.connect();
      print("소켓 연결을 시작합니다: ${dotenv.get('SOCKET_URL')}");
    } catch (e) {
      print("소켓 연결 초기화 중 오류 발생: $e");
    }
  }

// 소켓 이벤트 핸들러 등록
  void _registerSocketEvents() {
    // 최초 연결 성공
    socket.onConnect((_) {
      print("소켓 연결 성공");

      // Provider 초기화 및 리스너 설정
      final context = AppRoute.context;
      if (context != null) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.setSocketListeners();
        chatProvider.initChatProvider();
      }
    });

    // 재연결 성공
    socket.onReconnect((_) {
      print("소켓 재연결 성공");

      // Provider 초기화
      final context = AppRoute.context;
      if (context != null) {
        context.read<ChatProvider>().onReconnect();
      }
    });

    // 연결 종료
    socket.onDisconnect((reason) {
      print("소켓 연결 종료: $reason");

      final context = AppRoute.context;
      if (context != null) {
        context.read<ChatProvider>().onDisconnect();
      }
    });

    // 연결 오류
    socket.onConnectError((error) {
      print("소켓 연결 오류: $error");
    });
  }


  void on(String event, Function(dynamic) handler) => socket.on(event, handler);
  void off(String event, [Function? handler]) => socket.off(event);
  void emit(String event, dynamic data) => socket.emit(event, data);
  void disconnect() => socket.disconnect();
  /// 서버에 이벤트를 보내고, 응답(Ack)을 handler에서 처리
  void emitWithAck(String event, dynamic data, Function handler) {
    socket.emitWithAck(
      event,
      data,
      ack: handler,  // 네임드 파라미터로 넘겨야 합니다
    );
  }
}