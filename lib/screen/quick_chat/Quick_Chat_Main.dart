import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/screen/quick_chat/Quick_Chat_More.dart';

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

  static const String _pageKey = 'quick_chat_main';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      _pageController.jumpToPage(homeProvider.currentMenu);
      _initializeAds();
      homeProvider.fetchMyLocalQuickChatRooms();
      _setupScrollListener();
    });
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

  /// 스크롤 리스너 설정
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // 스크롤이 맨 아래에서 200픽셀 이내에 도달했을 때
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Provider에서 중복 요청 처리를 하므로 직접 호출
        homeProvider.fetchMyLocalQuickChatRooms();
      }
    });
  }

  @override
  void dispose() {
    // AdManager 헬퍼 사용하여 페이지 광고 정리
    AdManager.disposePageAds(_pageKey);
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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuTabs(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) {
                  homeProvider.setMenu(value);
                },
                children: List.generate(homeProvider.quickChatMenu.length, (index) {
                  return _buildQuickChatPage(index);
                }),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar() {
    return NadalAppbar(
      title: '번개챗',
      actions: [
        NadalIconButton(
          onTap: () {
            context.push('/searchRoom?isOpen=TRUE');
          },
          icon: CupertinoIcons.search,
        ),
        SizedBox(width: 8.w),
        NadalIconButton(
          onTap: () {
            context.push('/createRoom?isOpen=TRUE');
          },
          image: 'assets/image/icon/chat_add.png',
        )
      ],
    );
  }

  /// 메뉴 탭 빌드
  Widget _buildMenuTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 12.w),
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(homeProvider.quickChatMenu.length, (index) {
              final menu = homeProvider.quickChatMenu[index];
              final isSelected = homeProvider.currentMenu == index;

              return GestureDetector(
                onTap: () {
                  homeProvider.setMenu(index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ]
                          : [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                  ),
                  child: Text(
                    menu,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// 퀵챗 페이지 빌드
  Widget _buildQuickChatPage(int index) {
    if (index == 0) {
      return _buildMainQuickChatPage();
    } else if (index == 1) {
      return QuickChatMore(homeProvider: homeProvider,);
    }
    return NadalEmptyList(title: '무슨페이지에요?');
  }

  /// 메인 퀵챗 페이지 (첫 번째 탭)
  Widget _buildMainQuickChatPage() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 상단 배너 광고
        SliverToBoxAdapter(
          child: SimpleBannerAdWidget(
            adKey: '${_pageKey}_banner',
            height: 50.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
        ),

        // 참가중인 번개챗 섹션
        _buildParticipatingRoomsSection(),

        // 구분선
        SliverToBoxAdapter(child: Divider()),

        // 내 지역 번개챗 섹션 헤더
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            child: Text(
              '내 지역 번개챗',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),

        // 내 지역 번개챗 리스트
        _buildLocalQuickChatSection(),
      ],
    );
  }

  /// 참가중인 번개챗 섹션
  Widget _buildParticipatingRoomsSection() {
    if (roomsProvider.quickRooms!.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: NadalEmptyList(
            title: '아직 참가중인 번개챗이 없어요',
            subtitle: '번개챗은 누구나 빠르게 경기 전용 채팅방 운영할 수 있어요\n7일간 미활동 시 자동 삭제돼요',
            onAction: () {
              context.push('/createRoom?isOpen=TRUE');
            },
            actionText: '번개챗 만들기',
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: roomsProvider.quickRooms!.length,
      itemBuilder: (context, index) {
        final roomEntry = roomsProvider.getQuickList(context)[index];
        final roomData = roomEntry.value;
        final chats = chatProvider.chat[roomData['roomId']];
        final latestChat = chats == null || chats.isEmpty
            ? null
            : chats.reduce((a, b) => a.chatId > b.chatId ? a : b);
        final chatText = _getChatText(latestChat);
        final unread = chatProvider.my[roomData['roomId']]?['unreadCount'];

        return ListTile(
          onTap: () => context.push('/room/${roomData['roomId']}'),
          leading: NadalRoomFrame(imageUrl: roomData['roomImage']),
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
            constraints: BoxConstraints(maxHeight: 24.h),
            child: Text(
              chatText,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          trailing: unread != null && unread != 0
              ? NadalRoomNotReadTag(number: unread)
              : null,
        );
      },
    );
  }

  /// 내 지역 번개챗 섹션
  Widget _buildLocalQuickChatSection() {
    if (homeProvider.myLocalQuickChatRooms == null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: Center(child: NadalCircular()),
        ),
      );
    }

    if(homeProvider.myLocalQuickChatRooms!.isEmpty){
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: NadalEmptyList(title: '아직 주변에 번개방이 없어요', subtitle: '번개방을 만들고 친구들과 게임을 진행해보세요',
            actionText: '방 만들기',
            onAction: ()=> context.push('/createRoom?isOpen=TRUE')
          ),
        ),
      ); 
    }

    return SliverList.builder(
      itemCount: _calculateTotalItemCount(homeProvider.myLocalQuickChatRooms!.length),
      itemBuilder: (context, index) {
        return _buildLocalChatItem(context, index, homeProvider.myLocalQuickChatRooms!);
      },
    );
  }

  /// 전체 아이템 개수 계산 (원본 아이템 + 광고)
  int _calculateTotalItemCount(int originalCount) {
    if (originalCount <= 3) return originalCount;

    // 3개 이상일 때만 광고 삽입
    // 4~6개 아이템마다 광고 1개 추가 (랜덤성)
    final adCount = (originalCount / 5).floor().clamp(0, 3); // 최대 3개 광고
    return originalCount + adCount;
  }

  /// 광고 위치 결정 (랜덤하지만 일정한 간격 유지)
  bool _isAdPosition(int totalIndex, int originalCount) {
    if (originalCount <= 3) return false;

    // 랜덤 시드를 위해 고정된 패턴 사용 (실제 랜덤이 아닌 의사 랜덤)
    final positions = <int>[];

    if (originalCount >= 4) positions.add(3); // 4번째 위치
    if (originalCount >= 8) positions.add(7); // 8번째 위치
    if (originalCount >= 12) positions.add(11); // 12번째 위치

    return positions.contains(totalIndex);
  }

  /// 실제 아이템 인덱스 계산
  int _getActualItemIndex(int totalIndex, int originalCount) {
    if (originalCount <= 3) return totalIndex;

    int actualIndex = totalIndex;

    // 광고 위치들을 빼서 실제 인덱스 계산
    if (totalIndex > 3) actualIndex--;
    if (totalIndex > 7) actualIndex--;
    if (totalIndex > 11) actualIndex--;

    return actualIndex.clamp(0, originalCount - 1);
  }

  /// 광고 키 생성
  String _getAdKey(int adPosition) {
    final adIndex = adPosition <= 3 ? 0 : adPosition <= 7 ? 1 : 2;
    return '${_pageKey}_nativeListTile_$adIndex';
  }

  /// 로컬 챗 아이템 빌드 (아이템 또는 광고)
  Widget _buildLocalChatItem(BuildContext context, int index, List<dynamic> items) {
    final originalCount = items.length;

    // 광고 위치인지 확인
    if (_isAdPosition(index, originalCount)) {
      return NativeListTileAdWidget(
        adKey: _getAdKey(index),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      );
    }

    // 실제 아이템 표시
    final actualIndex = _getActualItemIndex(index, originalCount);
    final item = items[actualIndex];

    return ListTile(
      onTap: () => context.push('/previewRoom/${item['roomId']}'),
      leading: NadalRoomFrame(imageUrl: item['roomImage']),
      title: Text(
        item['roomName'],
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 36.h),
              child: Text(
                _getItemDescription(item),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Text(
              '${item['memberCount']}/200',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 채팅 텍스트 생성
  String _getChatText(dynamic latestChat) {
    if (latestChat == null) return '';

    switch (latestChat.type) {
      case ChatType.text:
        return latestChat.contents;
      case ChatType.image:
        return '사진';
      case ChatType.schedule:
        return '일정';
      default:
        return '삭제된 메시지 입니다';
    }
  }

  /// 아이템 설명 생성
  String _getItemDescription(dynamic item) {
    final description = item['description'] as String;
    final tag = item['tag'] as String;

    if (description.isNotEmpty) {
      return description;
    } else if (tag.isNotEmpty) {
      return tag;
    } else {
      return '정보없음';
    }
  }
}