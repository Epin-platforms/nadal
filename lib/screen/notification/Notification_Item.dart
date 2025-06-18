import 'package:intl/intl.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';

import '../../manager/project/Import_Manager.dart';
import 'Notification_Icons.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({super.key, required this.notification, required this.provider});
  final NotificationModel notification;
  final NotificationProvider provider;
  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {

  String _getTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM월 dd일 HH:mm').format(dateTime);
    }
  }

  // 안전한 읽음 처리 및 라우팅
  Future<void> _handleNotificationTap() async {
    try {
      // 읽지 않은 알림인 경우 읽음 처리
      await widget.provider.deleteNotification(widget.notification.notificationId);

      // 라우팅 처리
      if (widget.notification.routing != null) {
        final routing = widget.notification.routing!;
        final form = !routing.startsWith('/') ? '/$routing' : routing;

        if (mounted) {
          context.push(form);
        }
      }
    } catch (e) {
      print('알림 탭 처리 오류: $e');
      // 에러가 발생해도 라우팅은 시도
      if (widget.notification.routing != null && mounted) {
        final routing = widget.notification.routing!;
        final form = !routing.startsWith('/') ? '/$routing' : routing;
        context.push(form);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 읽음 여부에 따른 스타일 변경
    final backgroundColor = widget.notification.isRead
        ? theme.cardColor
        : colorScheme.primaryContainer;

    // 시간 형식 지정
    final timeStr = _getTimeString(widget.notification.createAt);

    // 아이콘 및 색상 결정
    final iconData = NotificationIcons.getIconByRoute(widget.notification.routing);
    final iconColor = widget.notification.isRead
        ? colorScheme.primary.withValues(alpha: 0.7)
        : colorScheme.primary;

    return ListTile(
      onTap: _handleNotificationTap,
      tileColor: backgroundColor,
      leading: Icon(iconData, color: iconColor,),
      title: Text(
        widget.notification.title ?? '새로운 소식이 도착했어요',
        style: theme.textTheme.labelLarge,
      ),
      subtitle: Text(
        widget.notification.subTitle ?? '지금 확인해볼까요?',
        style: theme.textTheme.labelMedium,
      ),
      trailing: Text(
        timeStr,
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}