import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/widget/Nadal_Level_Frame.dart';
import 'package:my_sports_calendar/widget/Nadal_Profile_Frame.dart';

import '../../../manager/project/Import_Manager.dart';

class MyProfileListCard extends StatefulWidget {
  const MyProfileListCard({super.key});

  @override
  State<MyProfileListCard> createState() => _MyProfileListCardState();
}

class _MyProfileListCardState extends State<MyProfileListCard> {
  late UserProvider userProvider;

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;
    return ListTile(
      onTap: ()=> context.push('/myProfile'),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      leading: NadalProfileFrame(imageUrl: user['profileImage'],),
      title: Text(user['name'],  style: Theme.of(context).textTheme.titleMedium,),
      subtitle: user['roomName'] == null ? null : Text(user['roomName'],  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),),
      trailing: SizedBox(
        width: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NadalLevelFrame(level: user['level']),
            Icon(CupertinoIcons.forward, size: 20, color: Theme.of(context).hintColor)
          ],
        ),
      ),
    );
  }
}
