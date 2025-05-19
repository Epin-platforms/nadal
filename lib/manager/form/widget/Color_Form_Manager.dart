import '../../project/Import_Manager.dart';

class ColorFormManager{
  static Color getTagColor(String tag) {
    final isDarkMode = Theme.of(AppRoute.context!).brightness == Brightness.dark;
    switch (tag) {
      case '게임':
        return isDarkMode ? Color(0xFF5AE6B8) : Color(0xFF3CB371);
      case '공지':
        return isDarkMode ? Color(0xFFFFC864) : Color(0xFFFFA500);
      case '모임':
        return isDarkMode ? Color(0xFF7CAEFF) : Color(0xFF5592FC);
      case '양도':
        return isDarkMode ? Color(0xFFFF8888) : Color(0xFFE06666);
      case '기타':
        return isDarkMode ? Color(0xFF90A4AE) : Color(0xFFB0BEC5);
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  static Color stateColor(int? state) {
    final isDarkMode = Theme.of(AppRoute.context!).brightness == Brightness.dark;
    switch (state) {
      case 0: // 모집중
        return isDarkMode ? Color(0xFF5AE6B8) : Color(0xFF3CB371);
      case 1: // 모집종료
        return isDarkMode ? Color(0xFF90A4AE) : Color(0xFFB0BEC5);
      case 2: // 추첨중
        return isDarkMode ? Color(0xFFFFC864) : Color(0xFFFFA500);
      case 3: // 게임중
        return isDarkMode ? Color(0xFF7CAEFF) : Color(0xFF5592FC);
      case 4: // 종료중
        return isDarkMode ? Color(0xFFFF8888) : Color(0xFFE06666);
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }
}