import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/model/share/Share_Parameter.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/util/handler/Deep_Link_Handler.dart';
import 'package:my_sports_calendar/widget/Share_Bottom_Sheet.dart';

import '../../../manager/project/Import_Manager.dart';

class FriendsSearch extends StatefulWidget {
  const FriendsSearch({super.key});

  @override
  State<FriendsSearch> createState() => _FriendsSearchState();
}

class _FriendsSearchState extends State<FriendsSearch> {
  late FriendsProvider provider;
  late TextEditingController _searchController;
  late ScrollController _contactController;

  @override
  void initState() {
    _searchController = TextEditingController();
    _contactController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_){
      provider.fetchContacts();
      _contactController.addListener((){
        if(_contactController.position.pixels >= _contactController.position.maxScrollExtent - 100){
          provider.fetchContacts();
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    provider = Provider.of<FriendsProvider>(context);

    return IosPopGesture(
        child: Material(
          child: Stack(
            children: [
              Scaffold(
                appBar: NadalAppbar(
                  title: '연락처로 찾기',
                  actions: [
                    NadalIconButton(
                        onTap: () {
                          shareApp(context);
                        },
                        icon: CupertinoIcons.share
                    ),
                    SizedBox(width: 8.w,),
                    NadalIconButton(
                        onTap: (){
                          DialogManager.showInputDialog(
                              context: context,
                              title: '사용자 찾기',
                              content: '찾으시는 사용자의 메일\n혹은 전화번호를 입력해주세요',
                              confirmText: '검색',
                              helper: '전화번호는 \'-\' 제외, 이메일은 주소 전체를 입력',
                              maxLength: 30,
                              keyType: TextInputType.text,
                              icon: Icon(BootstrapIcons.search),
                              cancelText: '최소',
                              onConfirm: (value){
                                 provider.searchUser(value, context);
                              }
                          );
                        },
                        icon: BootstrapIcons.person_add,
                    )
                  ],
                ),
                body: SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 24,),
                        if(provider.myContactList.isEmpty)
                          Expanded(
                            child: NadalEmptyList(
                              title: '음.. 나달을 사용하는 사용자가 없네요',
                              subtitle: '친구를 초대해 함께 경기를 진행해보세요',
                              actionText: '친구 초대',
                              onAction: (){
                                showModalBottomSheet(context: context, builder: (context){
                                  return ShareBottomSheet(shareParameter: ShareParameter(
                                      title: '친구가 나달에서 애타게 기다리고있어요',
                                      link: null,
                                      imageUrl: null,
                                      subTitle: '지금 같이 나달에서 경기해요',
                                      routing: '')
                                  );
                                });
                              },
                            ),
                          )
                        else
                          provider.contactLoading ?
                              Expanded(child: Center(
                                child: NadalCircular(),
                              ))
                              :
                         //연락처 친구 목록
                         Expanded(
                           child: ListView.builder(
                              controller: _contactController,
                              itemCount: provider.myContactList.length,
                              itemBuilder: (context, index){
                                final item = provider.myContactList[index];
                                return ListTile(
                                  onTap:(){
                                    context.push('/user/${item['uid']}');
                                  } ,
                                  leading: NadalProfileFrame(
                                    imageUrl: item['profileImage'],
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16.r, horizontal: 16.r),
                                  title: Text(item['nickName'],  style: Theme.of(context).textTheme.titleMedium,),
                                  subtitle: Text(item['roomName'] ?? '무소속',
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
                              },
                           ),
                         )
                      ],
                    )
                ),
                    ),

              if(provider.searchLoading)
                Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(60),
                      alignment: Alignment.center,
                      child: NadalCircular(),
                    )
                )
            ],
          ),
        ));
  }
}
