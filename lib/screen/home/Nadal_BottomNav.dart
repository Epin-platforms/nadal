import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/cupertino.dart';
import '../../manager/project/Import_Manager.dart';

class NadalBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const NadalBottomNav({super.key, required this.currentIndex, required this.onTap});

  // 🔧 배지 위젯 분리로 성능 최적화
  Widget _buildBadge(int count, context) {
    if (count <= 0) return const SizedBox.shrink();

    return Positioned(
      top: -2.r,
      right: -2.r,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 16.r,
          minHeight: 16.r,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ThemeManager.warmAccent,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: count > 99 ? 4.r : 3.r,
          vertical: 2.r,
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 🔧 아이콘 + 배지 컨테이너
  Widget _buildIconWithBadge({
    required IconData icon,
    required int badgeCount,
    required BuildContext context
  }) {
    return SizedBox(
      width: 24.r,
      height: 24.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24.r),
          _buildBadge(badgeCount, context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      type: BottomNavigationBarType.fixed,
      elevation: 8.r,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12.sp,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12.sp,
      ),
      items: [
        // 🔧 MY 탭 - 일반 클럽 배지
        BottomNavigationBarItem(
          icon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = chatProvider.getUnreadCount(
                roomsProvider.rooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: BootstrapIcons.circle,
                badgeCount: unreadCount, context: context,
              );
            },
          ),
          activeIcon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = chatProvider.getUnreadCount(
                roomsProvider.rooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: BootstrapIcons.person_circle,
                badgeCount: unreadCount, context: context,
              );
            },
          ),
          label: 'MY',
        ),

        // 🔧 번개챗 탭 - 퀵 룸 배지
        BottomNavigationBarItem(
          icon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = chatProvider.getUnreadCount(
                roomsProvider.quickRooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: CupertinoIcons.chat_bubble_2,
                badgeCount: unreadCount, context: context,
              );
            },
          ),
          activeIcon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = chatProvider.getUnreadCount(
                roomsProvider.quickRooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: CupertinoIcons.chat_bubble_2_fill,
                badgeCount: unreadCount, context: context,
              );
            },
          ),
          label: '아무니티',
        ),

        // 🔧 더보기 탭 - 배지 없음
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.three_dots, size: 24.r),
          activeIcon: Icon(BootstrapIcons.three_dots, size: 24.r),
          label: '더보기',
        ),
      ],
    );
  }
}
