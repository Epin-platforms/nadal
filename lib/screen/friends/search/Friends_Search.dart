import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Empty_List.dart';
import 'package:my_sports_calendar/widget/Search_Text_Field.dart';

import '../../../manager/project/Import_Manager.dart';

class FriendsSearch extends StatelessWidget {
  const FriendsSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendsProvider>(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '친구 검색',
          ),
          body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 24,),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SearchTextField(controller: TextEditingController())),
                    if(provider.friends.isEmpty)
                      SizedBox(
                        height: 300,
                        child: NadalEmptyList(
                          title: '아직 추가한 친구가 없어요',
                          subtitle: '지금 친구를 찾아서 추가해보세요',
                          actionText: '친구 추가하기',
                          onAction: (){

                          },
                        ),
                      )
                  ],
                ),
              )
          ),
      ));
  }
}
