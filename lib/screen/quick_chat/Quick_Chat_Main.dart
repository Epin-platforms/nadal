import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/screen/league/League_Page.dart';
import 'package:my_sports_calendar/screen/quick_chat/My_Quick_Chat.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      initializePageSetting();
    });
  }

  void initializePageSetting() async{
    _pageController.jumpToPage(homeProvider.currentMenu);
    homeProvider.fetchMyLocalQuickChatRooms();
  }



  @override
  void dispose() {
    _pageController.dispose();
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
      title: '아무니티',
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
  return MyQuickChat(homeProvider: homeProvider, roomsProvider: roomsProvider, chatProvider: chatProvider,);
    } else if(index == 1){
      return LeaguePage();
    }else if (index == 2) {
      return QuickChatMore(homeProvider: homeProvider,);
    }
    return NadalEmptyList(title: '무슨페이지에요?');
  }




}