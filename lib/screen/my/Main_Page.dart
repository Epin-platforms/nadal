import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/notification/Notification_Provider.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Profile_List_Card.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Rooms.dart';
import 'package:my_sports_calendar/screen/my/widget/My_Schedule_Calendar.dart';

import '../../manager/project/Import_Manager.dart';
import '../../widget/AlwaysScrollableScrollBehavior.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.homeProvider});
  final HomeProvider homeProvider;
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late UserProvider userProvider;
  late RoomsProvider roomsProvider;

  Future<void> _refresh() async{
    roomsProvider.roomInitialize();
    userProvider.fetchUserData();
    userProvider.fetchMySchedules(DateTime.now(), force: true);
  }


  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    userProvider = Provider.of<UserProvider>(context);
    roomsProvider = Provider.of<RoomsProvider>(context);
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
              if(notificationProvider.notifications != null && notificationProvider.notifications!.where((e)=> e.isRead).isNotEmpty)
              Positioned(
                  top: 0, right: 0,
                  child: Container(
                    height: 8.r, width: 8.r,
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
      body: SafeArea(
          child: RefreshIndicator(
            onRefresh: ()=> _refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: MyProfileListCard()),
                SliverToBoxAdapter(child: _homeDivider()),
                SliverToBoxAdapter(
                  child: MyScheduleCalendar(),
                ),
                SliverToBoxAdapter(child: _homeDivider()),
                SliverToBoxAdapter(child: MyRooms()),
              ],
            ),
          )
      )
    );
  }

  Widget _homeDivider(){
    return Divider(height: 0.5, thickness: 0.5, color: Theme.of(AppRoute.navigatorKey.currentContext!).highlightColor, indent: 16, endIndent: 16,);
  }
}
