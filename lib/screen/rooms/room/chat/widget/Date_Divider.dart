import 'package:intl/intl.dart';

import '../../../../../animation/Fade_In_Animation.dart';
import '../../../../../manager/project/Import_Manager.dart';

class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 오늘, 어제, 기타 날짜 포맷 설정
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = '오늘';
    } else if (messageDate == yesterday) {
      dateText = '어제';
    } else {
      final formatter = DateFormat('yyyy년 M월 d일', 'ko_KR');
      dateText = formatter.format(date);
    }

    return FadeInAnimation(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                dateText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
