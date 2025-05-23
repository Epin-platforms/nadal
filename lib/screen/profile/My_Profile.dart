
import 'package:my_sports_calendar/provider/auth/profile/My_Profile_Provider.dart';
import 'package:my_sports_calendar/screen/profile/widget/My_Profile_Card.dart';
import 'package:my_sports_calendar/screen/profile/widget/My_Profile_Menu.dart';
import '../../manager/project/Import_Manager.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        child: Text('메뉴', style: Theme.of(context).textTheme.titleLarge,)
                    ),
                    ListTile(
                      onTap: (){
                        context.push('/friends');
                      },
                      leading: Icon(BootstrapIcons.people_fill, size: 24.r, color: Theme.of(context).colorScheme.primary),
                      title: Text('친구목록', style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
            )
        );
      }
    );
  }
}
