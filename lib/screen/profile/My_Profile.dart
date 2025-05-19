import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/provider/auth/profile/My_Profile_Provider.dart';
import 'package:my_sports_calendar/screen/profile/Friends_List.dart';
import 'package:my_sports_calendar/screen/profile/widget/My_Profile_Card.dart';
import 'package:my_sports_calendar/screen/profile/widget/My_Profile_Menu.dart';
import 'package:my_sports_calendar/widget/Nadal_Icon_Button.dart';
import '../../manager/project/Import_Manager.dart';
import '../../widget/Nadal_Empty_List.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_)=> MyProfileProvider(),
      lazy: true,
      builder: (context, child) {
        final provider = Provider.of<MyProfileProvider>(context);
        return Scaffold(
            appBar: NadalAppbar(
              actions: [
                NadalIconButton(
                    onTap: (){
                      context.push('/myProfile/profileMore');
                    },
                    icon: BootstrapIcons.gear,
                )
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyProfileCard(provider: provider),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: Theme.of(context).highlightColor,
                    ),
                    MyProfileMenu(),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: Theme.of(context).highlightColor,
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('친구', style: Theme.of(context).textTheme.titleLarge,),
                            IconButton(onPressed: (){}, icon: Icon(BootstrapIcons.person_add, color: Theme.of(context).colorScheme.onSurface,))
                          ],
                        )
                    ),
                    if(context.watch<FriendsProvider>().friends.isEmpty)
                    NadalEmptyList(
                      title: '아직 추가한 친구가 없어요',
                      subtitle: '지금 친구를 찾아서 추가해보세요',
                      actionText: '친구 추가하기',
                      onAction: (){

                      },
                    )
                    else
                    FriendsList()
                  ],
                ),
              ),
            )
        );
      }
    );
  }
}
