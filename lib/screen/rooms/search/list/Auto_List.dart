import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';

class AutoList extends StatelessWidget {
  const AutoList({super.key, required this.provider});
  final SearchRoomProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autoTextList = provider.autoTextSearch;

    if (autoTextList.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: autoTextList.length,
      itemBuilder: (context, index) => _buildAutoTextItem(
        context,
        theme,
        autoTextList[index],
        index,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 100.h,
      alignment: Alignment.center,
      child: Text(
        '검색 결과가 없습니다',
        style: TextStyle(
          fontSize: 14.sp,
          color: theme.hintColor,
        ),
      ),
    );
  }

  Widget _buildAutoTextItem(
      BuildContext context,
      ThemeData theme,
      String item,
      int index,
      ) {
    // 안전한 텍스트 처리
    final safeItem = _sanitizeText(item);
    if (safeItem.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _handleItemTap(safeItem),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            _buildLeadingIcon(theme),
            SizedBox(width: 8.w),
            _buildItemText(theme, safeItem),
            SizedBox(width: 8.w),
            _buildTrailingIcon(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Icon(
      CupertinoIcons.search,
      size: 14.r,
      color: theme.hintColor,
    );
  }

  Widget _buildItemText(ThemeData theme, String text) {
    return Expanded(
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTrailingIcon(ThemeData theme) {
    return Icon(
      CupertinoIcons.arrow_turn_down_right,
      size: 14.r,
      color: theme.hintColor,
    );
  }

  void _handleItemTap(String item) {
    try {
      provider.onSubmit(item);
    } catch (e) {
      debugPrint('자동완성 항목 선택 실패: $e');
    }
  }

  String _sanitizeText(String text) {
    if (text.isEmpty) return '';

    // 기본 텍스트 정제
    final sanitized = text.trim();

    // 길이 제한 (UI 안정성을 위해)
    if (sanitized.length > 100) {
      return '${sanitized.substring(0, 97)}...';
    }

    return sanitized;
  }
}