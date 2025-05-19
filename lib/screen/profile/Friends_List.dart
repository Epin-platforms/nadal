import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import '../../manager/project/Import_Manager.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  late FriendsProvider provider;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<FriendsProvider>(context);
    return  ListView.builder(
        shrinkWrap: true,
        itemCount: provider.friends.length,
        itemBuilder: (context, index){
          final item = provider.friends[index];
          return NadalUserProfile(item: item);
        }
    );
  }
}
