import 'package:intl/intl.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';

import '../../manager/project/Import_Manager.dart';
import 'Notification_Icons.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({super.key, required this.notification});
  final NotificationModel notification;

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

    return const Placeholder();
  }
}
