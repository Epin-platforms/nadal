import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'package:my_sports_calendar/screen/notification/Notification_Item.dart';

import '../../manager/project/Import_Manager.dart';
import '../../model/app/Notifications_Model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late NotificationProvider notificationProvider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      notificationProvider.fetchNotifications();
    });
    super.initState();
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return '오늘';
    } else if (notificationDate == yesterday) {
      return '어제';
    } else if (now.difference(notificationDate).inDays < 7) {
      return '이번 주';
    } else if (notificationDate.month == now.month && notificationDate.year == now.year) {
      return '이번 달';
    } else {
      return DateFormat('yyyy년 MM월').format(date);
    }
  }

  // 날짜 그룹의 우선순위를 반환
  int _getDateGroupPriority(String dateGroup) {
    switch (dateGroup) {
      case '오늘':
        return 1;
      case '어제':
        return 2;
      case '이번 주':
        return 3;
      case '이번 달':
        return 4;
      default:
        return 5; // 과거 월들
    }
  }

  @override
  Widget build(BuildContext context) {
    notificationProvider = Provider.of<NotificationProvider>(context);

    if(notificationProvider.notifications == null){
      return GestureDetector(
        onTap: ()=> context.pop(),
        child: Material(
          child: Center(
            child: NadalCircular(),
          ),
        ),
      );
    }

    final grouped = <String, List<NotificationModel>>{};

    for (var notification in notificationProvider.notifications!) {
      final dateStr = _getDateGroup(notification.createAt);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(notification);
    }

    // 각 그룹 내에서 최신순으로 정렬
    grouped.forEach((key, notifications) {
      notifications.sort((a, b) => b.createAt.compareTo(a.createAt));
    });

    // 키를 우선순위와 날짜 순으로 정렬 (최신이 위로)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final priorityA = _getDateGroupPriority(a);
        final priorityB = _getDateGroupPriority(b);

        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }

        // 같은 우선순위(과거 월들)인 경우 문자열 비교로 최신 월이 위로
        return b.compareTo(a);
      });

    return IosPopGesture(
        child: Scaffold(
            appBar: NadalAppbar(
              title: '알림',
            ),
            body:
            SafeArea(
              child: sortedKeys.isNotEmpty ?
              ListView.builder(
                  padding:  EdgeInsets.only(top: 8.h, bottom: 24.h),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index){
                    final dateKey = sortedKeys[index];
                    final notificationGroup = grouped[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                          child: Text(
                            dateKey,
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ...notificationGroup.map((notification) =>
                            NotificationItem(notification: notification, provider: notificationProvider,)
                        ),
                      ],
                    );
                  }
              ) : Padding(
                padding: EdgeInsets.only(bottom: 50.h),
                child: NadalEmptyList(  title: '지금은 조용하네요',
                  subtitle: '알림이 오면 바로 알려드릴게요!',),
              ),
            )
        )
    );
  }
}