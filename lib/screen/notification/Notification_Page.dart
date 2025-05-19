import 'package:animate_do/animate_do.dart';
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
      notificationProvider.initialize();
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

    // 키를 날짜 순으로 정렬
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 날짜가 먼저 오도록

    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '알림',
          ),
          body: 
          SafeArea(
            child: sortedKeys.isNotEmpty ?
            ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index){
                  final dateKey = sortedKeys[index];
                  final notificationGroup = grouped[dateKey]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          dateKey,
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...notificationGroup.map((notification) =>
                          FadeInUp(
                            duration: Duration(milliseconds: 300 + (50 * notificationGroup.indexOf(notification))),
                            child: NotificationItem(notification: notification),
                          )
                      ),
                    ],
                  );
                }
            ) : Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: NadalEmptyList(  title: '지금은 조용하네요',
                subtitle: '알림이 오면 바로 알려드릴게요!',),
            ),
          )
        )
    );
  }
}
