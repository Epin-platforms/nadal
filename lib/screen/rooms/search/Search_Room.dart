import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Auto_List.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Recently_List.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Recommend_List.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Result_List.dart';
import 'package:my_sports_calendar/widget/Search_Text_Field.dart';

import '../../../manager/project/Import_Manager.dart';

class SearchRoom extends StatelessWidget {
  const SearchRoom({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user!;
    return ChangeNotifierProvider(
        create: (_)=> SearchRoomProvider(user),
        builder: (context, child){
          final provider = Provider.of<SearchRoomProvider>(context);
          return IosPopGesture(
              child: Scaffold(
                appBar: NadalAppbar(
                  title: '클럽 검색',
                ),
                body: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: SearchTextField(controller: provider.searchController, node: provider.searchNode, onSubmit: (String value)=> provider.onSubmit(value),)),
                        Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  provider.mode == SearchMode.recently ?
                                  //최근 검색 기록 리스트
                                  RecentlyList(provider: provider) :
                                  provider.mode == SearchMode.auto ?
                                  //자동완성 텍스트
                                  AutoList(provider: provider) :
                                  ResultList(provider: provider),
                                  if(provider.recentlySearch.isNotEmpty || provider.autoTextSearch.isNotEmpty || provider.mode == SearchMode.result)
                                    ...[
                                      SizedBox(height: 24,),
                                      if(provider.recommendRooms.isNotEmpty)
                                      Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: Text('이런 클럽은 어떠세요?', style: Theme.of(context).textTheme.titleLarge,)),
                                      RecommendList(provider: provider)
                                    ],

                                  SizedBox(height: 50,)
                                ],
                              )
                            )
                        )
                      ],
                    )
                ),
              )
          );
        },
    );
  }
}
