import 'package:intl/intl.dart';
import '../manager/project/Import_Manager.dart';

class NadalSimpleScheduleList extends StatelessWidget {
  const NadalSimpleScheduleList({super.key, required this.schedule});
  final Map schedule;
  @override
  Widget build(BuildContext context) {
    final isAllDay = schedule['isAllDay'] == 1;
    final start = DateTime.parse(schedule['startDate']);
    final end = DateTime.parse(schedule['endDate']);
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    final timeFormat = DateFormat('HH:mm');
    
    return InkWell(
      onTap: ()=> context.push('/schedule/${schedule['scheduleId']}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀 + 상태
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule['title'] ?? '제목 없음',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if(schedule['state'] != null)
                NadalScheduleState(state: schedule['state'])
              ],
            ),
      
            SizedBox(height: 10),
      
            // 일정 날짜 및 시간
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  isAllDay
                      ? '${dateFormat.format(start)} 종일'
                      : '${dateFormat.format(start)} ${timeFormat.format(start)} ~ ${timeFormat.format(end)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
      
            SizedBox(height: 8),
      
            // 하단 태그 / 참가자 수
            Row(
              children: [
                NadalScheduleTag(tag: schedule['tag']),
                Spacer(),
                if (schedule['useParticipation'] == 1)
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${schedule['participationCount']}명',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
              ],
            ),
      
          ],
        ),
      ),
    );
  }
}
