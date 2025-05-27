import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';

class AutoList extends StatelessWidget {
  const AutoList({super.key, required this.provider});
  final SearchRoomProvider provider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: provider.autoTextSearch.length,
      itemBuilder: (context, index){
        final item = provider.autoTextSearch[index];
        return InkWell(
          onTap: ()=> provider.onSubmit(item),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.search, size: 14.r, color: theme.hintColor),
                      SizedBox(width: 8.w,),
                      Expanded(
                          child: Text(item, style: theme.textTheme.bodyMedium,)
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w,),
                Icon(CupertinoIcons.arrow_turn_down_right, size: 14.r, color: theme.hintColor,)
              ],
            ),
          ),
        );
      },
    );
  }
}
