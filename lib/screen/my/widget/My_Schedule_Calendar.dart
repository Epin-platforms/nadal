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
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      userProvider.fetchMySchedules(_focusedDay);
    });
  }

  // 특정 날짜에 일정을 불러오는 함수 (메모리 효율화)
  List<Map> _getEventsForDay(DateTime day, List<Map> schedules) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return schedules.where((schedule) {
      final startDate = DateTimeManager.parseUtcToLocalSafe(schedule['startDate']);
      if (startDate == null) return false;
      final scheduleDay = DateTime(startDate.year, startDate.month, startDate.day);
      return scheduleDay == dayKey;
    }).toList();
  }

  void _onPageChanged(DateTime dateTime) {
    if (mounted) {
      setState(() {
        _focusedDay = dateTime;
        _selectedDay = dateTime;
      });

      // 데이터 로드
      final userProvider = context.read<UserProvider>();
      userProvider.fetchMySchedules(dateTime);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (mounted) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
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
    required BuildContext context,
    required DateTime day,
    required List<Map> events,
    required bool isSelected,
    required bool isOutside,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(day.year, day.month, day.day);
    final isToday = dayKey == today;

    return Opacity(
      opacity: isOutside ? 0.3 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: isSelected ? Border.all(
            color: Theme.of(context).colorScheme.primary,
          ) : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 표시
            Center(
              child: Container(
                padding: EdgeInsets.all(1.r),
                decoration: BoxDecoration(
                  color: isToday ? CupertinoColors.activeGreen : null,
                  borderRadius: BorderRadius.circular(3.r),
                ),
                child: Text(
                  DateFormat('d').format(day),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isToday
                        ? const Color(0xfff1f1f1)
                        : day.weekday == 6
                        ? CupertinoColors.activeBlue
                        : day.weekday == 7
                        ? CupertinoColors.destructiveRed
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            // 이벤트 표시
            if (events.isNotEmpty)
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: Text(
                      events.first['title'] ?? '',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xfff1f1f1),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
              ),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'MY ',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: DateFormat('M월').format(_selectedDay),
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' 일정',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NadalIconButton(
                    icon: BootstrapIcons.calendar2_plus,
                    onTap: () {
                      context.push('/create/schedule',
                          extra: ScheduleParams(date: _selectedDay));
                    },
                  ),
                ],
              ),
            ),

            // 캘린더
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TableCalendar<Map>(
                locale: 'ko_KR',
                focusedDay: _focusedDay,
                currentDay: _selectedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 1000)),
                lastDay: DateTime.now().add(const Duration(days: 1000)),
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarFormat: CalendarFormat.month,
                headerVisible: false,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day, schedules),
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: ThemeManager.infoColor, // 원하는 색상으로 변경
                    borderRadius: BorderRadius.circular(20),
                  ),
                  markerSize: 6.0, // 마커 크기
                  markersMaxCount: 3, // 최대 마커 개수
                  markersAlignment: Alignment.bottomCenter, // 마커 위치
                ),
                calendarBuilders: CalendarBuilders<Map>(
                  // 요일 헤더
                  dowBuilder: (context, day) {
                    final text = TextFormManager.returnWeek(date: day);
                    return Center(
                      child: FittedBox(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: day.weekday == 6
                                ? Colors.blueAccent
                                : day.weekday == 7
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },

                  // 선택된 날짜
                  selectedBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day, schedules);
                    return _buildCalendarDay(
                      context: context,
                      day: day,
                      events: events,
                      isSelected: true,
                      isOutside: false,
                    );
                  },

                  // 기본 날짜
                  defaultBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day, schedules);
                    return _buildCalendarDay(
                      context: context,
                      day: day,
                      events: events,
                      isSelected: false,
                      isOutside: false,
                    );
                  },

                  // 다른 월 날짜
                  outsideBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day, schedules);
                    return _buildCalendarDay(
                      context: context,
                      day: day,
                      events: events,
                      isSelected: false,
                      isOutside: true,
                    );
                  },
                ),
              ),
            ),

            const Divider(),

            // 선택된 날짜의 일정 목록
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 표시
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Text(
                      '${DateFormat(
                        _selectedDay.year != DateTime.now().year
                            ? 'yyyy년 M월 d일'
                            : 'M월 d일',
                      ).format(_selectedDay)} (${TextFormManager.returnWeek(date: _selectedDay)})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 일정 목록 또는 빈 목록
                  if (selectedDayEvents.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedDayEvents.length,
                      itemBuilder: (context, index) {
                        final schedule = selectedDayEvents[index];
                        return NadalSimpleScheduleList(
                          schedule: schedule,
                          onTap: () => _onScheduleTap(schedule),
                        );
                      },
                    )
                  else
                    SizedBox(
                      height: 230.h,
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
            ),
          ],
        );
      },
    );
  }
}