import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';

class RecentlyList extends StatelessWidget {
  const RecentlyList({super.key, required this.provider});
  final SearchRoomProvider provider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: provider.recentlySearch.length,
        itemBuilder: (context, index){
          final item = provider.recentlySearch[index];
          return InkWell(
            onTap: ()=> provider.onSubmit(item),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.clock, size: 14, color: theme.hintColor),
                          SizedBox(width: 4,),
                          Expanded(
                              child: Text(item, style: theme.textTheme.bodyMedium,)
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8,),
                    Icon(CupertinoIcons.arrow_turn_down_right, size: 14, color: theme.hintColor,)
                  ],
                ),
            ),
          );
        },
    );
  }
}
