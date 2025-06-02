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
        ? colorScheme.primary // 발신자 메시지는 메인 컬러 사용
        : (isDark
        ? const Color(0xFF2A2A36) // 다크 모드에서 수신자 메시지는 어두운 회색
        : const Color(0xFFF2F2F7)); // 라이트 모드에서 수신자 메시지는 밝은 회색

    // 텍스트 색상
    // 텍스트 색상 - 좋은 대비를 위해 색상 조정
    final textColor = isSender
        ? theme.colorScheme.onPrimary // 발신자 메시지는 흰색 텍스트
        : (isDark
        ? Colors.white.withValues(alpha: 0.9) // 다크 모드에서 수신자 메시지는 밝은 텍스트
        : const Color(0xFF1F1F1F)); // 라이트 모드에서 수신자 메시지는 거의 검은색 텍스트

    // 보조 색상 (날짜, 버튼 등)
    final secondaryColor = isSender
        ? theme.colorScheme.onPrimary // 발신자 메시지는 흰색 텍스트
        : (isDark
        ? Colors.white.withValues(alpha: 0.9) // 다크 모드에서 수신자 메시지는 밝은 텍스트
        : const Color(0xFF1F1F1F)); // 라이트 모드에서 수신자 메시지는 거의 검은색 텍스트

    // 강조 색상 (버튼 배경 등)
    final accentColor = isSender
        ? Colors.white.withValues(alpha: 0.25)
        : (isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06));

    // 날짜 포맷 설정
    final formatter = startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day && startDate.hour == 6 && endDate.hour == 23 ?
    '하루종일' :
    DateFormat('M월 d일 (E) HH:mm', 'ko_KR');

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
        margin:  EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
        padding:  EdgeInsets.all(14.r),
        constraints:  BoxConstraints(maxWidth: 220.w),
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
                padding:  EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                margin:  EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12.sp,
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
                fontSize: 16.sp,
                color: textColor,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8.h),

            // 일정 기간
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 14.sp,
                  color: secondaryColor,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    formatter is DateFormat ?
                    '${formatter.format(startDate)} ~ ${formatter.format(endDate)}' :
                    formatter.toString(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 스케줄 보기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/schedule/$scheduleId'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14.sp,
                        color: textColor,
                      ),
                       SizedBox(width: 4.w),
                      Text(
                        '스케줄 보기',
                        style: TextStyle(
                          fontSize: 13.sp,
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