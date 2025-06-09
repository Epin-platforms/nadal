import 'package:flutter/cupertino.dart';

import '../../manager/project/Import_Manager.dart';
import '../../provider/app/Advertisement_Provider.dart';
import '../../widget/Nadal_Room_Frame.dart';
import '../../widget/Nadal_Room_NotRead_Tag.dart';

class QuickChatMain extends StatefulWidget {
  const QuickChatMain({super.key});

  @override
  State<QuickChatMain> createState() => _QuickChatMainState();
}

class _QuickChatMainState extends State<QuickChatMain> {
  late RoomsProvider roomsProvider;
  late HomeProvider homeProvider;
  late ChatProvider chatProvider;
  late PageController _pageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    _pageController = PageController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((callback){
     _pageController.jumpToPage(homeProvider.currentMenu);
     _initializeAds();
     homeProvider.fetchMyLocalQuickChatRooms();
     _scrollController.addListener((){
       if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100){
         homeProvider.fetchMyLocalQuickChatRooms();
       }
     });
    });
    super.initState();
  }

  /// 광고 초기화
  Future<void> _initializeAds() async {
    final adProvider = context.read<AdvertisementProvider>();

    // 배너 광고 로드
    await adProvider.loadBannerNativeAd('quick_chat_main_banner');

    // 리스트용 네이티브 광고 미리 로드 (최대 5개)
    for (int i = 0; i < 5; i++) {
      await adProvider.loadListItemNativeAd('quick_chat_main_list_$i');
    }
  }

  @override
  void dispose() {
    AdManager.disposePageAds('quick_chat_main');
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    roomsProvider = Provider.of<RoomsProvider>(context);
    homeProvider = Provider.of<HomeProvider>(context);
    chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: NadalAppbar(
        title: '번개챗',
        actions: [
          NadalIconButton(
            onTap: (){
              context.push('/searchRoom?isOpen=TRUE');
            },
            icon: CupertinoIcons.search,
          ),
          SizedBox(width: 8,),
          NadalIconButton(
            onTap: (){
              context.push('/createRoom?isOpen=TRUE');
            },
            image: 'assets/image/icon/chat_add.png',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 15.h, horizontal: 12.w),
              child: Consumer<HomeProvider>(
                builder: (context, homeProvider, child) {
                  return Wrap(
                    spacing: 8.w, // 가로 간격
                    runSpacing: 8.h, // 세로 간격 (줄바꿈 시)
                    children: List.generate(homeProvider.quickChatMenu.length, (index) {
                      final menu = homeProvider.quickChatMenu[index];
                      final isSelected = homeProvider.currentMenu == index; // 선택 상태 확인 (필요시)

                      return GestureDetector(
                        onTap: (){
                          homeProvider.setMenu(index);
                          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                              ]
                                  : [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withValues(alpha:0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
                              width: 1.5.w,
                            ),
                          ),
                          child: Text(
                            menu,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              )
            ),
            Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value){
                    homeProvider.setMenu(value);
                  },
                  children: List.generate(homeProvider.quickChatMenu.length, (index){
                    return _quickChatPages(index);
                  }),
                )
            )
          ],
        ),
      ),
    );
  }
  
  Widget _quickChatPages(int index){
    if(index == 0){
      return CustomScrollView(
        slivers: [
          //배너광고
          SliverToBoxAdapter(
            child:  BannerNativeAdWidget(
              adKey: 'quick_chat_main_banner',
              height: 80.h,
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
          ),
          roomsProvider.quickRooms!.isEmpty ? 
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300.h,
                  child: NadalEmptyList(title: '아직 참가중인 번개챗이 없어요', subtitle: '번개챗은 누구나 빠르게 경기 전용 채팅방 운영할 수 있어요\n7일간 미활동 시 자동 삭제돼요', onAction: (){
                    context.push('/createRoom?isOpen=TRUE');
                  }, actionText: '번개챗 만들기',),
                ),
              ) :
          SliverList.builder(
              itemCount: roomsProvider.quickRooms!.length,
              itemBuilder: (context, index){
                final roomEntry = roomsProvider.getQuickList(context)[index];
                final roomData = roomEntry.value;
                final chats = chatProvider.chat[roomData['roomId']];
                final latestChat = chats == null || chats.isEmpty ? null : chats.reduce((a, b) => a.chatId > b.chatId ? a : b);
                final chatText = latestChat == null ? '' : latestChat.type == ChatType.text ? latestChat.contents : latestChat.type == ChatType.image ? '사진' : latestChat.type == ChatType.schedule ? '일정' : '삭제된 메시지 입니다';
                final unread = chatProvider.my[roomData['roomId']]?['unreadCount'];
                return ListTile(
                  onTap: ()=> context.push('/room/${roomData['roomId']}'),
                  leading: NadalRoomFrame(imageUrl: roomData['roomImage'],),
                  title: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: roomData['roomName'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: [
                              TextSpan(
                                text: ' ${roomData['memberCount'] ?? 0}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: 24.h
                      ),
                      child: Text(chatText ?? '', style: Theme.of(context).textTheme.labelMedium,)),
                  trailing: unread != null && unread != 0 ? NadalRoomNotReadTag(number: unread) : null,
                );
              }
          ),
          SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverToBoxAdapter(
            child: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w, vertical: 15.h),
                child: Text('내 지역 번개챗', style: Theme.of(context).textTheme.titleMedium,)),
          ),
          if (homeProvider.myLocalQuickChatRooms == null) SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(child: NadalCircular()),
              ),
            ) else SliverList.builder(
              itemCount: homeProvider.myLocalQuickChatRooms!.length,
              itemBuilder: (context, index){
                final item = homeProvider.myLocalQuickChatRooms![index];
                return ListTile(
                  onTap: ()=> context.push('/previewRoom/${item['roomId']}'),
                  leading: NadalRoomFrame(
                    imageUrl: item['roomImage'],
                  ),
                  title: Text(item['roomName'], style: Theme.of(context).textTheme.titleMedium,),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 24.h
                            ),
                            child: Text('${
                                (item['description'] as String).isEmpty ?
                                (item['tag'] as String).isEmpty ? '정보없음' : item['tag'] : item['description']
                            }', style: Theme.of(context).textTheme.bodySmall,)),
                      ),
                      Padding(
                          padding: EdgeInsetsGeometry.only(left: 8.w),
                        child: Text('${item['memberCount']}/200', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),),
                      )
                    ],
                  ),
                );
              }
          )
        ],
      );
    }else if(index == 1){
      return CustomScrollView(

      );
    }
    return NadalEmptyList(title: '무슨페이지에요?');
  }
}
