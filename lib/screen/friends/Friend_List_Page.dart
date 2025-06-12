import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import 'package:my_sports_calendar/screen/friends/Follower_List.dart';
import 'package:my_sports_calendar/screen/friends/Following_List.dart';

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
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_){
      final page = context.read<HomeProvider>().currentFriendMenu;
      _pageController.jumpToPage(page);
    });
    super.initState();
  }

  @override
  void dispose() {
    provider.clearSelected();
    super.dispose();
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuTabs(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index){
                    context.read<HomeProvider>().setFriendMenu(index);
                  },
                  children: [
                    FollowingList(provider: provider, selectable: widget.selectable),
                    FollowerList(provider: provider, selectable: widget.selectable,)
                  ],
                ),
              )
            ],
          )
    ));
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
            children: List.generate(homeProvider.friendMenu.length, (index) {
              final menu = homeProvider.friendMenu[index];
              final isSelected = homeProvider.currentFriendMenu == index;

              return GestureDetector(
                onTap: () {
                  homeProvider.setFriendMenu(index);
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

}
