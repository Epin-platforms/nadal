import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Profile_List_Card.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Rooms.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Schedule_Calendar.dart';

import '../../manager/project/Import_Manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.homeProvider});
  final HomeProvider homeProvider;
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final pallet = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: NadalAppbar(
        title: 'MY',
        actions: [
          Stack(
            children: [
              NadalIconButton(
                  onTap: ()=> context.push('/notification'),
                  icon: CupertinoIcons.bell,
              ),
              if(notificationProvider.notifications != null && notificationProvider.notifications!.where((e)=> !e.isRead).isNotEmpty)
              Positioned(
                  top: 0, right: 0,
                  child: Container(
                    height: 8, width: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pallet.primary
                    ),
                  )
              )
            ],
          )
        ],
      ),
      body: GestureDetector(
        onTap: ()=> print('${MediaQuery.of(context).size}'),
        child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MyProfileListCard(),
                  _homeDivider(),
                  MyScheduleCalendar(),
                  _homeDivider(),
                  MyRooms()
                ],
              ),
            )
        ),
      )
    );
  }

  Widget _homeDivider(){
    return Divider(height: 0.5, thickness: 0.5, color: Theme.of(AppRoute.navigatorKey.currentContext!).highlightColor, indent: 16, endIndent: 16,);
  }
}
