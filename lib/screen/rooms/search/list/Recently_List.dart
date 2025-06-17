import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';

class RecentlyList extends StatelessWidget {
  const RecentlyList({super.key, required this.provider});
  final SearchRoomProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentSearches = provider.recentlySearch;

    if (recentSearches.isEmpty) {
      return _buildEmptyState(theme);
    }

    // 최근 검색어를 역순으로 표시 (최신 항목이 위로)
    final reversedList = recentSearches.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        final item = reversedList[index];
        final actualIndex = recentSearches.length - 1 - index;

        return _buildRecentItem(
          context,
          theme,
          item,
          actualIndex,
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 48.r,
            color: theme.hintColor.withValues(alpha:0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '최근 검색 기록이 없습니다',
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(
      BuildContext context,
      ThemeData theme,
      String item,
      int actualIndex,
      ) {
    final safeItem = _sanitizeText(item);
    if (safeItem.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _handleItemTap(safeItem),
      onLongPress: () => _handleItemLongPress(context, actualIndex, safeItem),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            _buildItemContent(theme, safeItem),
            SizedBox(width: 8.w),
            _buildTrailingIcon(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildItemContent(ThemeData theme, String item) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 18.r,
            color: theme.hintColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              item,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIcon(ThemeData theme) {
    return Icon(
      CupertinoIcons.arrow_turn_down_right,
      size: 16.r,
      color: theme.hintColor,
    );
  }

  void _handleItemTap(String item) {
    try {
      provider.onSubmit(item);
    } catch (e) {
      debugPrint('최근 검색 항목 선택 실패: $e');
    }
  }

  void _handleItemLongPress(BuildContext context, int index, String item) {
    _showDeleteDialog(context, index, item);
  }

  void _showDeleteDialog(BuildContext context, int index, String item) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('검색 기록 삭제'),
          content: Text('\'$item\'을(를) 검색 기록에서 삭제하시겠습니까?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleItemDelete(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _handleItemDelete(int index) {
    try {
      provider.removeRecentlySearch(index);
    } catch (e) {
      debugPrint('최근 검색 항목 삭제 실패: $e');
    }
  }

  String _sanitizeText(String text) {
    if (text.isEmpty) return '';

    final sanitized = text.trim();

    // 길이 제한
    if (sanitized.length > 50) {
      return '${sanitized.substring(0, 47)}...';
    }

    return sanitized;
  }
}