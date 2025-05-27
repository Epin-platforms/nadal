import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/room/Room_Schedule_Provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../manager/project/Import_Manager.dart';

class RoomCalendar extends StatelessWidget {
  const RoomCalendar({super.key, required this.provider});
  final RoomScheduleProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TableCalendar(
        locale: 'ko_KR',
        focusedDay: provider.focusedDay,
        currentDay: provider.selectedDay,
        firstDay: DateTime.now().subtract(const Duration(days: 1000)),
        lastDay: DateTime.now().add(const Duration(days: 1000)),
        startingDayOfWeek: StartingDayOfWeek.sunday,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          provider.setDate(focusDay: focusedDay, selectDay: selectedDay);
        },

        onPageChanged: (dateTime){
          provider.setDate(focusDay: dateTime, selectDay: dateTime);
          provider.fetchRoomSchedule(dateTime);
        },

        headerVisible: false,

        calendarBuilders: CalendarBuilders(
          //요일 설정
          dowBuilder: (context, day){
            final text = TextFormManager.returnWeek(date: day);
            return Center(
              child: FittedBox(
                child: Text(text , style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: day.weekday == 6 ? Colors.blueAccent : day.weekday == 7 ? Colors.redAccent :
                Theme.of(context).colorScheme.onSurface)),
              ),
            );
          },

          //선택한 날짜 스타일
          selectedBuilder: (context, day, focusedDay) {
            final events = provider.getEventsForDay(day);
            final now = DateTime.now();
            final today2 = DateTime(day.year, day.month, day.day);
            final today = DateTime(now.year, now.month, now.day);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.3
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Center(
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            color:  today2 == today ? ThemeManager.successColor : null,
                            borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text(DateFormat('d').format(day), style: Theme.of(context).textTheme.labelMedium?.copyWith(color:
                        today2 == today ? const Color(0xfff1f1f1) :
                        day.weekday == 6 ? CupertinoColors.activeBlue :
                        day.weekday == 7 ? CupertinoColors.destructiveRed :
                        Theme.of(context).colorScheme.onSurface, fontWeight: today2 == today ? FontWeight.w600 : FontWeight.w400),),
                      ),
                      if(events.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(3)
                              ),
                              padding: EdgeInsets.all(3),
                              child: Text(events.first['title'], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary,overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w500, fontSize: 8),),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          },

          //선택된 달 기본 모양
          defaultBuilder: (context, day, focusedDay){
            final events = provider.getEventsForDay(day);
            final now = DateTime.now();
            final today2 = DateTime(day.year, day.month, day.day);
            final today = DateTime(now.year, now.month, now.day);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                          color:  today2 == today ? CupertinoColors.activeGreen : null,
                          borderRadius: BorderRadius.circular(3)
                      ),
                      child: Text(DateFormat('d').format(day), style: Theme.of(context).textTheme.labelMedium?.copyWith(color:
                      today2 == today ? const Color(0xfff1f1f1) :
                      day.weekday == 6 ? CupertinoColors.activeBlue :
                      day.weekday == 7 ? CupertinoColors.destructiveRed :
                      Theme.of(context).colorScheme.onSurface, fontWeight: today2 == today ? FontWeight.w600 : FontWeight.w400),),
                    ),
                    if(events.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(3)
                            ),
                            padding: EdgeInsets.all(3),
                            child: Text(events.first['title'], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary ,overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w800, fontSize: 10),),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            );
          },

          //기타날짜
          outsideBuilder: (context, day, focusedDay){
            final events = provider.getEventsForDay(day);
            return Opacity(
              opacity: 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text(DateFormat('d').format(day), style: Theme.of(context).textTheme.labelMedium?.copyWith(color:
                        day.weekday == 6 ? CupertinoColors.activeBlue :
                        day.weekday == 7 ? CupertinoColors.destructiveRed :
                        Theme.of(context).colorScheme.onSurface),),
                      ),
                      if(events.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(3)
                              ),
                              padding: EdgeInsets.all(3),
                              child: Text(events.first['title'], style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w800, fontSize: 10),),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
