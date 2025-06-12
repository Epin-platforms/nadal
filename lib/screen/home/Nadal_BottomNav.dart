import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/cupertino.dart';
import '../../manager/project/Import_Manager.dart';

class NadalBottomNav extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const NadalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap
  });

  @override
  State<NadalBottomNav> createState() => _NadalBottomNavState();
}

class _NadalBottomNavState extends State<NadalBottomNav> {
  // 🔧 배지 계산 최적화를 위한 캐시
  int _cachedMyUnreadCount = 0;
  int _cachedQuickUnreadCount = 0;
  Timer? _badgeUpdateTimer;

  @override
  void dispose() {
    _badgeUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
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
        // MY 탭 (일반 클럽)
        BottomNavigationBarItem(
          icon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = _getMyUnreadCount(
                chatProvider,
                roomsProvider.rooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: BootstrapIcons.circle,
                badgeCount: unreadCount,
                context: context,
              );
            },
          ),
          activeIcon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = _getMyUnreadCount(
                chatProvider,
                roomsProvider.rooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: BootstrapIcons.person_circle,
                badgeCount: unreadCount,
                context: context,
              );
            },
          ),
          label: 'MY',
        ),

        // 번개챗 탭 (퀵 룸)
        BottomNavigationBarItem(
          icon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = _getQuickUnreadCount(
                chatProvider,
                roomsProvider.quickRooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: CupertinoIcons.chat_bubble_2,
                badgeCount: unreadCount,
                context: context,
              );
            },
          ),
          activeIcon: Consumer2<RoomsProvider, ChatProvider>(
            builder: (context, roomsProvider, chatProvider, child) {
              final unreadCount = _getQuickUnreadCount(
                chatProvider,
                roomsProvider.quickRooms?.keys.toList(),
              );
              return _buildIconWithBadge(
                icon: CupertinoIcons.chat_bubble_2_fill,
                badgeCount: unreadCount,
                context: context,
              );
            },
          ),
          label: '아무니티',
        ),

        // 더보기 탭 (배지 없음)
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.three_dots, size: 24.r),
          activeIcon: Icon(BootstrapIcons.three_dots, size: 24.r),
          label: '더보기',
        ),
      ],
    );
  }

  // 🔧 MY 탭 안읽은 메시지 수 가져오기 (캐시 적용)
  int _getMyUnreadCount(ChatProvider chatProvider, List<int>? roomIds) {
    try {
      if (roomIds == null || roomIds.isEmpty) {
        _cachedMyUnreadCount = 0;
        return 0;
      }

      // 🔧 재연결 중이거나 로딩 중이면 캐시된 값 사용
      if (chatProvider.socketLoading && _cachedMyUnreadCount > 0) {
        return _cachedMyUnreadCount;
      }

      final newCount = chatProvider.getUnreadCount(roomIds);

      // 🔧 캐시 업데이트 (디바운싱 적용)
      if (newCount != _cachedMyUnreadCount) {
        _scheduleUnreadUpdate(() => _cachedMyUnreadCount = newCount);
      }

      return newCount;
    } catch (e) {
      print('MY unread count 가져오기 오류: $e');
      return _cachedMyUnreadCount;
    }
  }

  // 🔧 퀵챗 탭 안읽은 메시지 수 가져오기 (캐시 적용)
  int _getQuickUnreadCount(ChatProvider chatProvider, List<int>? roomIds) {
    try {
      if (roomIds == null || roomIds.isEmpty) {
        _cachedQuickUnreadCount = 0;
        return 0;
      }

      // 🔧 재연결 중이거나 로딩 중이면 캐시된 값 사용
      if (chatProvider.socketLoading && _cachedQuickUnreadCount > 0) {
        return _cachedQuickUnreadCount;
      }

      final newCount = chatProvider.getUnreadCount(roomIds);

      // 🔧 캐시 업데이트 (디바운싱 적용)
      if (newCount != _cachedQuickUnreadCount) {
        _scheduleUnreadUpdate(() => _cachedQuickUnreadCount = newCount);
      }

      return newCount;
    } catch (e) {
      print('퀵챗 unread count 가져오기 오류: $e');
      return _cachedQuickUnreadCount;
    }
  }

  // 🔧 배지 업데이트 스케줄링 (디바운싱)
  void _scheduleUnreadUpdate(VoidCallback updateCallback) {
    _badgeUpdateTimer?.cancel();
    _badgeUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        updateCallback();
      }
    });
  }

  // 아이콘과 배지를 함께 표시하는 위젯
  Widget _buildIconWithBadge({
    required IconData icon,
    required int badgeCount,
    required BuildContext context,
  }) {
    return SizedBox(
      width: 24.r,
      height: 24.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24.r),
          if (badgeCount > 0) _buildBadge(badgeCount, context),
        ],
      ),
    );
  }

  // 🔧 최적화된 배지 위젯
  Widget _buildBadge(int count, BuildContext context) {
    // 99+ 처리
    final displayText = count > 99 ? '99+' : count.toString();
    final isLarge = count > 99;

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
          // 🔧 그림자 추가로 가독성 향상
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 4.r : 3.r,
          vertical: 2.r,
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: isLarge ? 9.sp : 10.sp, // 🔧 99+ 일 때 폰트 크기 조정
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}