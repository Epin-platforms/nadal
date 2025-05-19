import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';

class RecommendList extends StatelessWidget {
  const RecommendList({super.key, required this.provider});
  final SearchRoomProvider provider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: provider.recommendRooms.length,
        itemBuilder: (context, index){
          final item = provider.recommendRooms[index];
          return ListTile(
            leading: NadalRoomFrame(imageUrl: item['roomImage'], size: 50,),
            title: Text(item['roomName'], style: theme.textTheme.titleMedium),
            subtitle: Text(item['tag'], style: theme.textTheme.labelMedium,),
            isThreeLine: true,
          );
        });
  }
}
