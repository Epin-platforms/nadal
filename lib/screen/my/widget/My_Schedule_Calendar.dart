import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/widget/Nadal_Simple_Schedule_List.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../manager/project/Import_Manager.dart';

class MyScheduleCalendar extends StatefulWidget {
  const MyScheduleCalendar({super.key});

  @override
  State<MyScheduleCalendar> createState() => _MyScheduleCalendarState();
}

class _MyScheduleCalendarState extends State<MyScheduleCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider.fetchMySchedules(_focusedDay);
      }
    });
  }

  List<Map> _getEventsForDay(DateTime day, List<Map> schedules) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return schedules.where((schedule) {
      final startDate = DateTime.tryParse(schedule['startDate'] ?? '');
      if (startDate == null) return false;
      final scheduleDay = DateTime(startDate.year, startDate.month, startDate.day);
      return scheduleDay == dayKey;
    }).toList();
  }

  void _onPageChanged(DateTime dateTime) {
    if (!mounted) return;

    setState(() {
      _focusedDay = dateTime;
      _selectedDay = dateTime;
    });

    final userProvider = context.read<UserProvider>();
    userProvider.fetchMySchedules(dateTime);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!mounted) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _onScheduleTap(Map schedule) async {
    try {
      await context.push('/schedule/${schedule['scheduleId']}');
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        await userProvider.updateSchedule(scheduleId: schedule['scheduleId']);
      }
    } catch (e) {
      print('스케줄 이동 실패: $e');
    }
  }

  Widget _buildCalendarDay({
    required DateTime day,
    required List<Map> events,
    required bool isSelected,
    required bool isOutside,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(day.year, day.month, day.day);
    final isToday = dayKey == today;
    final hasEvents = events.isNotEmpty;

    return GestureDetector(
      onTap: isOutside ? null : () => _onDaySelected(day, day),
      child: Container(
        margin: EdgeInsets.all(2.w),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          // 오늘만 배경색
          color: isToday ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1) : null,
          // 선택된 날짜는 보더로 표시
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.w)
              : null,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isOutside
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3)
                    : isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            // 이벤트가 있으면 dot만 표시
            if (hasEvents && !isOutside) ...[
              SizedBox(height: 4.h),
              Container(
                width: 4.r,
                height: 4.r,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final schedules = userProvider.schedules;
        final selectedDayEvents = _getEventsForDay(_selectedDay, schedules);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'MY ',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: DateFormat('M월').format(_selectedDay),
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' 일정',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/create/schedule',
                          extra: ScheduleParams(date: _selectedDay));
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        BootstrapIcons.calendar2_plus,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18.r,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // 캘린더
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha:0.1),
                    width: 1.w,
                  ),
                ),
                child: TableCalendar<Map>(
                  locale: 'ko_KR',
                  focusedDay: _focusedDay,
                  currentDay: _selectedDay,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  calendarFormat: CalendarFormat.month,

                  // 애니메이션 비활성화로 안정성 확보
                  sixWeekMonthsEnforced: false,
                  pageAnimationEnabled: false,

                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: _onPageChanged,

                  // 헤더 스타일
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronVisible: true,
                    rightChevronVisible: true,
                    headerPadding: EdgeInsets.symmetric(vertical: 16.h),
                    titleTextStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    leftChevronIcon: Icon(
                      BootstrapIcons.chevron_left,
                      size: 16.r,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      BootstrapIcons.chevron_right,
                      size: 16.r,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // 캘린더 스타일
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    cellMargin: EdgeInsets.zero,
                    cellPadding: EdgeInsets.zero,
                    // 모든 기본 스타일 제거하여 커스텀 빌더만 사용
                    defaultDecoration: const BoxDecoration(),
                    weekendDecoration: const BoxDecoration(),
                    holidayDecoration: const BoxDecoration(),
                    selectedDecoration: const BoxDecoration(),
                    todayDecoration: const BoxDecoration(),
                    outsideDecoration: const BoxDecoration(),
                    tablePadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  ),

                  // 요일 헤더
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                    weekendStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),

                  // 커스텀 빌더
                  calendarBuilders: CalendarBuilders(
                    // 요일 헤더
                    dowBuilder: (context, day) {
                      final text = TextFormManager.returnWeek(date: day);
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: day.weekday == 6
                                ? Colors.blue.shade400
                                : day.weekday == 7
                                ? Colors.red.shade400
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                        ),
                      );
                    },

                    // 모든 날짜 스타일을 통합 처리
                    defaultBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(day, schedules);
                      final isSelected = isSameDay(_selectedDay, day);
                      final isOutside = day.month != _focusedDay.month;
                      return _buildCalendarDay(
                        day: day,
                        events: events,
                        isSelected: isSelected,
                        isOutside: isOutside,
                      );
                    },

                    selectedBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(day, schedules);
                      return _buildCalendarDay(
                        day: day,
                        events: events,
                        isSelected: true,
                        isOutside: false,
                      );
                    },

                    todayBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(day, schedules);
                      final isSelected = isSameDay(_selectedDay, day);
                      return _buildCalendarDay(
                        day: day,
                        events: events,
                        isSelected: isSelected,
                        isOutside: false,
                      );
                    },

                    outsideBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(day, schedules);
                      return _buildCalendarDay(
                        day: day,
                        events: events,
                        isSelected: false,
                        isOutside: true,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 구분선
              Container(
                height: 1.h,
                color: Theme.of(context).dividerColor.withValues(alpha:0.1),
              ),

              SizedBox(height: 20.h),

              // 선택된 날짜 표시
              Text(
                '${DateFormat(
                  _selectedDay.year != DateTime.now().year
                      ? 'yyyy년 M월 d일'
                      : 'M월 d일',
                ).format(_selectedDay)} (${TextFormManager.returnWeek(date: _selectedDay)})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 16.h),

              // 일정 목록
              if (selectedDayEvents.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedDayEvents.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final schedule = selectedDayEvents[index];
                    return NadalSimpleScheduleList(
                      schedule: schedule,
                      onTap: () => _onScheduleTap(schedule),
                    );
                  },
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 210.h),
                  child: NadalEmptyList(
                    title: '이 날은 아직 비어 있어요',
                    subtitle: '일정을 하나 추가해볼까요?',
                    onAction: () {
                      context.push('/create/schedule',
                          extra: ScheduleParams(date: _selectedDay));
                    },
                    actionText: '일정 추가하기',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}