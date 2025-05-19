import 'package:flutter/cupertino.dart';

import '../manager/project/Import_Manager.dart';

class NadalUserProfile extends StatelessWidget {
  const NadalUserProfile({super.key, required this.item});
  final Map item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: NadalProfileFrame(
        imageUrl: item['profileImage'],
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.r, horizontal: 16.r),
      title: Text(item['name'],  style: Theme.of(context).textTheme.titleMedium,),
      subtitle: item['roomName'] == null ? null : Text(item['roomName'],
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),),
      trailing: SizedBox(
        width: 80.w,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NadalLevelFrame(level: item['level']),
            Icon(CupertinoIcons.forward, size: 20.r, color: Theme.of(context).hintColor)
          ],
        ),
      ),
    );
  }
}
