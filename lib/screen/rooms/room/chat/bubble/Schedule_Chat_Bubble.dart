import 'package:intl/intl.dart';

import '../../../../../animation/Animate_Bubble.dart';
import '../../../../../manager/project/Import_Manager.dart';

class ScheduleChatBubble extends StatelessWidget {
  const ScheduleChatBubble({
    super.key,
    required this.title,
    required this.scheduleId,
    required this.startDate,
    required this.endDate,
    required this.tag,
    required this.isSender,
    required this.tail, required this.animation,
    
  });

  final bool animation;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? tag;
  final bool isSender;
  final bool tail;
  final int scheduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 깔끔한 말풍선 색상 설정 (텍스트 버블과 동일한 스타일)
    final backgroundColor = isSender
        ? colorScheme.primary
        : theme.highlightColor;

    // 텍스트 색상
    final textColor = isSender
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.9);

    // 보조 색상 (날짜, 버튼 등)
    final secondaryColor = isSender
        ? theme.colorScheme.surfaceContainerLowest
        : theme.colorScheme.surfaceContainerHighest;

    // 강조 색상 (버튼 배경 등)
    final accentColor = isSender
        ? Colors.white.withValues(alpha: 0.25)
        : (isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06));

    // 날짜 포맷 설정
    final formatter = DateFormat('M월 d일 (E) HH:mm', 'ko_KR');

    // 말풍선 모양 설정 (꼬리 유무에 따라)
    final borderRadius = BorderRadius.only(
      topLeft:  Radius.circular(isSender || !tail ? 18 : 4),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(18),
      bottomRight: Radius.circular(isSender && tail ? 4 : 18),
    );

    return AnimatedBubble(
      isSender: isSender,
      duration: const Duration(milliseconds: 350),
      animation: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 표시
            if (tag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // 스케줄 제목
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // 일정 기간
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: secondaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${formatter.format(startDate)} ~ ${formatter.format(endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 스케줄 보기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/schedule/$scheduleId'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: textColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '스케줄 보기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}