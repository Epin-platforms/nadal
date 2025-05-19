// 알림 유형 아이콘 헬퍼 클래스
import '../../manager/project/Import_Manager.dart';

class NotificationIcons {
  static const IconData message = BootstrapIcons.chat_dots;
  static const IconData activity = BootstrapIcons.activity;
  static const IconData reminder = BootstrapIcons.bell;
  static const IconData update = BootstrapIcons.arrow_clockwise;
  static const IconData event = BootstrapIcons.calendar_event;
  static const IconData promotion = BootstrapIcons.gift;
  static const IconData alert = BootstrapIcons.exclamation_circle;
  static const IconData success = BootstrapIcons.check_circle;

  // 라우팅 경로에 따른 아이콘 결정
  static IconData getIconByRoute(String? route) {
    if (route == null) return reminder;

    if (route.contains('message') || route.contains('chat')) {
      return message;
    } else if (route.contains('schedule') || route.contains('calendar')) {
      return event;
    } else if (route.contains('update') || route.contains('version')) {
      return update;
    } else if (route.contains('activity') || route.contains('stats')) {
      return activity;
    } else if (route.contains('promo') || route.contains('coupon')) {
      return promotion;
    } else if (route.contains('success') || route.contains('complete')) {
      return success;
    } else if (route.contains('alert') || route.contains('warning')) {
      return alert;
    }

    return reminder;
  }
}