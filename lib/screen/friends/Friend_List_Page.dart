import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';

import '../../manager/project/Import_Manager.dart';
import '../../provider/app/Advertisement_Provider.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key, required this.selectable});
  final bool selectable;
  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  late FriendsProvider provider;
  late ScrollController _scrollController;
  static const String _pageKey = 'friend_list_page';

  @override
  void initState() {
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_){
      provider.getFriends();
      _initializeAds();
      _scrollController.addListener((){
        if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100){
          provider.getFriends();
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    AdManager.disposePageAds(_pageKey);
    _scrollController.dispose();
    provider.clearSelected();
    super.dispose();
  }

  /// 광고 초기화
  Future<void> _initializeAds() async {
    final adProvider = context.read<AdvertisementProvider>();

    // 배너 광고와 네이티브 ListTile형 광고 로드
    await adProvider.loadBannerAd('${_pageKey}_banner');

    // 네이티브 ListTile형 광고 미리 로드 (최대 3개)
    for (int i = 0; i < 3; i++) {
      await adProvider.loadNativeListTileAd('${_pageKey}_nativeListTile_$i');
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<FriendsProvider>(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '친구',
            actions: [
              if(provider.friends.isNotEmpty)
              NadalIconButton(onTap: (){
                context.push('/search/friends');
              }, icon: BootstrapIcons.search,)
            ],
          ),
          body: SafeArea(
            child: provider.friends.isEmpty ?
                Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: NadalEmptyList(
                    title: '아직 팔로우한 친구가 없어요',
                    subtitle: '지금 친구를 찾아서 팔로우해보세요',
                    actionText: '친구 찾기',
                    onAction: (){
                      context.push('/search/friends');
                    },
                  ),
                ) :

                Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsetsGeometry.only(top: 24.h),
                            sliver: SliverToBoxAdapter(
                              child: SimpleBannerAdWidget(
                                adKey: '${_pageKey}_banner',
                                height: 50.h,
                                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              ),
                            ),
                          ),
                          SliverList.builder(
                              itemCount: provider.friends.length,
                              itemBuilder: (context, index){
                                final item = provider.friends[index];
                                return ListTile(
                                  onTap:(){
                                    if(widget.selectable){
                                      provider.setSelectedUid(value: item['friendUid']);
                                    }else{
                                      context.push('/user/${item['friendUid']}');
                                    }
                                  } ,
                                  leading: NadalProfileFrame(
                                    imageUrl: item['profileImage'],
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16.r, horizontal: 16.r),
                                  title: Text(item['nickName'],  style: Theme.of(context).textTheme.titleMedium,),
                                  subtitle: Text(item['roomName'] ?? '무소속',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),),
                                  trailing: SizedBox(
                                    width: 90.w,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        NadalLevelFrame(level: item['level']),
                                        if(widget.selectable)
                                          provider.selectedUid.contains(item['friendUid']) ?
                                          Icon(CupertinoIcons.checkmark_square_fill, color: Theme.of(context).colorScheme.primary,) :
                                          Icon(CupertinoIcons.square_fill, color: Theme.of(context).hintColor,)
                                        else
                                          Icon(CupertinoIcons.forward, size: 24.r, color: Theme.of(context).hintColor)
                                      ],
                                    ),
                                  ),
                                );
                              }
                          )
                        ],
                      ),
                    ),
                    if(widget.selectable)
                      NadalButton(
                        isActive: provider.selectedUid.isNotEmpty,
                        title: '선택완료',
                        onPressed: ()=> context.pop(
                            provider.selectedUid
                        ),
                      )
                  ],
                )
          )
    ));
  }
}
