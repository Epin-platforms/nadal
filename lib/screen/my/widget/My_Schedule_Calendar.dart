import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
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
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    if (!mounted || _isInitialized) return;

    final userProvider = context.read<UserProvider>();
    userProvider.fetchMySchedules(_focusedDay);
    _isInitialized = true;
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
      if(!context.read<UserProvider>().canSchedule()){ //스케줄 생성이 불가할 경우 다이알로그
        DialogManager.showBasicDialog(title: '스케줄을 사용할 수 없어요', content: '이용방침 미준수로 스케줄 사용이 제재됩니다', confirmText: '확인');
        return;
      }

      await context.push('/schedule/${schedule['scheduleId']}');

      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider.updateSchedule(scheduleId: schedule['scheduleId']);
      }

    } catch (e) {
      debugPrint('스케줄 이동 실패: $e');
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
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isToday ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1) : null,
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
            if (hasEvents && !isOutside) ...[
              SizedBox(height: 2.h),
              Container(
                width: 16.r,
                height: 4.r,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8)
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
                  Row(
                    children: [
                      Text('MY', style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      )),
                      Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 4.w),
                        child:  Text(DateFormat('M월').format(_selectedDay),
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                           color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        )),
                      ),
                    Text('일정', style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    )),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if(!context.read<UserProvider>().canSchedule()){ //스케줄 생성이 불가할 경우 다이알로그
                        DialogManager.showBasicDialog(title: '스케줄을 사용할 수 없어요', content: '이용방침 미준수로 스케줄 사용이 제재됩니다', confirmText: '확인');
                        return;
                      }

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

              // 캘린더 - Listener로 수직 드래그만 상위로 전달
              Listener(
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent) {
                    // 마우스 스크롤 이벤트를 상위로 전달
                    return;
                  }
                },
                child: GestureDetector(
                  onPanUpdate: (details) {
                    // 수직 스크롤이 수평 스크롤보다 클 때만 상위로 전달
                    if (details.delta.dy.abs() > details.delta.dx.abs()) {
                      // 이 제스처를 상위 스크롤뷰로 전달
                      return;
                    }
                  },
                  child: Container(
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

                      // 안전성 및 경량화 설정
                      sixWeekMonthsEnforced: false,
                      pageAnimationEnabled: false,
                      pageJumpingEnabled: false,

                      // 수평 스와이프만 허용 (월 변경용)
                      availableGestures: AvailableGestures.horizontalSwipe,

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

                      // 캘린더 스타일 - 성능 최적화
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

                        // 통합된 날짜 빌더로 성능 최적화
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

              // 일정 목록 - 최적화된 렌더링
              if (selectedDayEvents.isNotEmpty)
                ...selectedDayEvents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final schedule = entry.value;
                  return Column(
                    children: [
                      if (index > 0) SizedBox(height: 8.h),
                      NadalSimpleScheduleList(
                        schedule: schedule,
                        onTap: () => _onScheduleTap(schedule),
                      ),
                    ],
                  );
                })
              else
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 210.h),
                  child: NadalEmptyList(
                    title: '이 날은 아직 비어 있어요',
                    subtitle: '일정을 하나 추가해볼까요?',
                    onAction: () {
                      if(!context.read<UserProvider>().canSchedule()){ //스케줄 생성이 불가할 경우 다이알로그
                        DialogManager.showBasicDialog(title: '스케줄을 사용할 수 없어요', content: '이용방침 미준수로 스케줄 사용이 제재됩니다', confirmText: '확인');
                        return;
                      }

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