import 'package:my_sports_calendar/manager/project/Import_Manager.dart';

/// 🔧 앱 초기화 순서 관리 클래스
class AppInitializationManager {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// 앱 초기화 상태 확인
  static bool get isInitialized => _isInitialized;
  static bool get isInitializing => _isInitializing;

  /// 🔧 메인 초기화 프로세스 (순차적 실행)
  static Future<void> initializeApp(BuildContext context) async {
    if (_isInitialized || _isInitializing) {
      debugPrint('🔄 앱이 이미 초기화됨 또는 진행 중 - 스킵');
      return;
    }

    try {
      _isInitializing = true;
      debugPrint('🚀 앱 초기화 프로세스 시작');

      // 1단계: RoomsProvider 초기화 (방 목록 로드)
      await _initializeRoomsProvider(context);

      // 2단계: ChatProvider 초기화 (소켓 연결 및 채팅 데이터 로드)
      await _initializeChatProvider(context);

      // 3단계: 기타 초기화
      await _initializeOtherProviders(context);

      _isInitialized = true;
      debugPrint('✅ 앱 초기화 프로세스 완료');

    } catch (e) {
      debugPrint('❌ 앱 초기화 실패: $e');
      throw e;
    } finally {
      _isInitializing = false;
    }
  }

  /// 1단계: RoomsProvider 초기화
  static Future<void> _initializeRoomsProvider(BuildContext context) async {
    try {
      debugPrint('🔧 1단계: RoomsProvider 초기화 시작');

      final roomsProvider = context.read<RoomsProvider>();
      await roomsProvider.roomInitialize();

      debugPrint('✅ 1단계: RoomsProvider 초기화 완료');
    } catch (e) {
      debugPrint('❌ RoomsProvider 초기화 실패: $e');
      throw e;
    }
  }

  /// 2단계: ChatProvider 초기화
  static Future<void> _initializeChatProvider(BuildContext context) async {
    try {
      debugPrint('🔧 2단계: ChatProvider 초기화 시작');

      final roomsProvider = context.read<RoomsProvider>();
      final chatProvider = context.read<ChatProvider>();

      // RoomsProvider의 데이터를 기반으로 ChatProvider 초기화
      await chatProvider.initializeAfterRooms(roomsProvider);

      debugPrint('✅ 2단계: ChatProvider 초기화 완료');
    } catch (e) {
      debugPrint('❌ ChatProvider 초기화 실패: $e');
      throw e;
    }
  }

  /// 3단계: 기타 Provider 초기화
  static Future<void> _initializeOtherProviders(BuildContext context) async {
    try {
      debugPrint('🔧 3단계: 기타 Provider 초기화 시작');

      // HomeProvider 초기화 (필요한 경우)
      try {
        final homeProvider = context.read<HomeProvider>();
        // HomeProvider의 특별한 초기화가 필요하다면 여기서 실행
        debugPrint('✅ HomeProvider 준비 완료');
      } catch (e) {
        debugPrint('⚠️ HomeProvider를 찾을 수 없음: $e');
      }

      // UserProvider 초기화 (필요한 경우)
      try {
        final userProvider = context.read<UserProvider>();
        // UserProvider의 특별한 초기화가 필요하다면 여기서 실행
        debugPrint('✅ UserProvider 준비 완료');
      } catch (e) {
        debugPrint('⚠️ UserProvider를 찾을 수 없음: $e');
      }

      debugPrint('✅ 3단계: 기타 Provider 초기화 완료');
    } catch (e) {
      debugPrint('❌ 기타 Provider 초기화 실패: $e');
      // 기타 Provider 실패는 전체 앱 초기화를 중단시키지 않음
    }
  }

  /// 🔧 백그라운드 복귀 시 재초기화 (필요한 경우)
  static Future<void> reinitializeAfterBackground(BuildContext context) async {
    if (!_isInitialized) {
      debugPrint('⚠️ 앱이 초기화되지 않았음 - 전체 초기화 실행');
      await initializeApp(context);
      return;
    }

    try {
      debugPrint('🔄 백그라운드 복귀 재초기화 시작');

      // ChatProvider만 재초기화 (RoomsProvider는 변경되지 않으므로 스킵)
      final chatProvider = context.read<ChatProvider>();

      // 소켓 재연결은 SocketManager에서 자동으로 처리됨
      // 필요한 경우 추가 처리

      debugPrint('✅ 백그라운드 복귀 재초기화 완료');
    } catch (e) {
      debugPrint('❌ 백그라운드 복귀 재초기화 실패: $e');
    }
  }

  /// 초기화 상태 리셋 (테스트용 또는 로그아웃 시)
  static void reset() {
    _isInitialized = false;
    _isInitializing = false;
    debugPrint('🔄 앱 초기화 상태 리셋');
  }

  /// 🔧 앱 상태 확인 및 필요시 재초기화
  static Future<void> ensureInitialized(BuildContext context) async {
    if (!_isInitialized && !_isInitializing) {
      await initializeApp(context);
    }
  }
}