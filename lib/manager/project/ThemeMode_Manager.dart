import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeManager {
  static final ThemeModeManager _instance = ThemeModeManager._internal();
  factory ThemeModeManager() => _instance;
  ThemeModeManager._internal();

  static const String _themeKey = 'epin.nadal.theme_mode';

  // ValueNotifier 사용 (setState 대신)
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  // 초기화
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getInt(_themeKey) ?? 0;
    themeModeNotifier.value = ThemeMode.values[savedTheme];
  }

  // 테마 변경 (경량화된 방식)
  Future<void> changeTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      themeModeNotifier.value = themeMode;
    } catch (e) {
      // 안전성: 에러 발생 시 기본값 유지
      debugPrint('테마 저장 실패: $e');
    }
  }

  // 현재 테마 가져오기
  ThemeMode get currentTheme => themeModeNotifier.value;

  // 다크 모드 여부 확인
  bool get isDarkMode => currentTheme == ThemeMode.dark;

  // 리소스 정리
  void dispose() {
    themeModeNotifier.dispose();
  }
}