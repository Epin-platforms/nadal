import 'package:intl/intl.dart';
import '../manager/project/Import_Manager.dart';

class NadalSimpleScheduleList extends StatelessWidget {
  const NadalSimpleScheduleList({
    super.key,
    required this.schedule,
    required this.onTap
  });

  final Map schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 안전한 데이터 추출
    final scheduleData = _extractScheduleData();

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 타이틀 + 상태
              _buildTitleRow(theme, colorScheme, scheduleData),

              SizedBox(height: 10.h),

              // 일정 날짜 및 시간
              _buildDateTimeRow(theme, scheduleData),

              SizedBox(height: 8.h),

              // 하단 태그 / 참가자 수
              _buildBottomRow(theme, colorScheme, scheduleData),
            ],
          ),
        ),
      ),
    );
  }

  // 안전한 데이터 추출
  Map<String, dynamic> _extractScheduleData() {
    try {
      final isAllDay = (schedule['isAllDay'] as int? ?? 0) == 1;

      DateTime? startDate;
      DateTime? endDate;

      // 안전한 날짜 파싱
      try {
        final startDateStr = schedule['startDate'] as String?;
        if (startDateStr != null) {
          startDate = DateTime.tryParse(startDateStr);
        }
      } catch (e) {
        print('시작 날짜 파싱 오류: $e');
      }

      try {
        final endDateStr = schedule['endDate'] as String?;
        if (endDateStr != null) {
          endDate =  DateTime.tryParse(endDateStr);
        }
      } catch (e) {
        print('종료 날짜 파싱 오류: $e');
      }

      return {
        'title': schedule['title'] as String? ?? '제목 없음',
        'isAllDay': isAllDay,
        'startDate': startDate,
        'endDate': endDate,
        'state': schedule['state'] as int?,
        'tag': schedule['tag'] as String?,
        'useParticipation': (schedule['useParticipation'] as int? ?? 0) == 1,
        'participationCount': schedule['participationCount'] as int? ?? 0,
      };
    } catch (e) {
      print('스케줄 데이터 추출 오류: $e');
      return {
        'title': '제목 없음',
        'isAllDay': false,
        'startDate': null,
        'endDate': null,
        'state': null,
        'tag': null,
        'useParticipation': false,
        'participationCount': 0,
      };
    }
  }

  // 타이틀 행 빌드
  Widget _buildTitleRow(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            data['title'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (data['state'] != null) ...[
          SizedBox(width: 8.w),
          NadalScheduleState(state: data['state'] as int),
        ],
      ],
    );
  }

  // 날짜/시간 행 빌드
  Widget _buildDateTimeRow(ThemeData theme, Map<String, dynamic> data) {
    final dateTimeText = _formatDateTime(data);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 16.r,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            dateTimeText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 하단 행 빌드 (태그 + 참가자)
  Widget _buildBottomRow(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 태그
        if (data['tag'] != null)
          NadalScheduleTag(tag: data['tag'] as String),

        const Spacer(),

        // 참가자 수
        if (data['useParticipation'] as bool)
          _buildParticipationCount(theme, data['participationCount'] as int),
      ],
    );
  }

  // 참가자 수 위젯
  Widget _buildParticipationCount(ThemeData theme, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.group_outlined,
          size: 16.r,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        SizedBox(width: 4.w),
        Text(
          '${count}명',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 날짜/시간 포맷팅
  String _formatDateTime(Map<String, dynamic> data) {
    try {
      final isAllDay = data['isAllDay'] as bool;
      final startDate = data['startDate'] as DateTime?;
      final endDate = data['endDate'] as DateTime?;

      if (startDate == null) {
        return '날짜 정보 없음';
      }

      final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');
      final timeFormat = DateFormat('HH:mm', 'ko_KR');

      if (isAllDay) {
        if (endDate != null && !DateTimeManager.isSameDay(startDate, endDate)) {
          return '${dateFormat.format(startDate)} ~ ${dateFormat.format(endDate)} 종일';
        }
        return '${dateFormat.format(startDate)} 종일';
      } else {
        if (endDate != null) {
          if (DateTimeManager.isSameDay(startDate, endDate)) {
            return '${dateFormat.format(startDate)} ${timeFormat.format(startDate)} ~ ${timeFormat.format(endDate)}';
          } else {
            return '${dateFormat.format(startDate)} ${timeFormat.format(startDate)} ~ ${dateFormat.format(endDate)} ${timeFormat.format(endDate)}';
          }
        }
        return '${dateFormat.format(startDate)} ${timeFormat.format(startDate)}';
      }
    } catch (e) {
      print('날짜 포맷팅 오류: $e');
      return '날짜 형식 오류';
    }
  }
}