import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/form/widget/Text_Form_Manager.dart';
import 'package:my_sports_calendar/model/schedule/Schedule_Params.dart';
import 'package:my_sports_calendar/widget/Nadal_Empty_List.dart';
import 'package:my_sports_calendar/widget/Nadal_Icon_Button.dart';
import 'package:my_sports_calendar/widget/Nadal_Simple_Schedule_List.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../manager/project/Import_Manager.dart';

class MyScheduleCalendar extends StatefulWidget {
  const MyScheduleCalendar({super.key});
  @override
  State<MyScheduleCalendar> createState() => _MyScheduleCalendarState();
}

class _MyScheduleCalendarState extends State<MyScheduleCalendar> {
  late UserProvider userProvider;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 특정 날짜에 일정을 불러오는 함수
  List<Map> _getEventsForDay(DateTime day, List<Map> schedules) {
    return schedules.where((schedule) => isSameDay(DateTime.parse(schedule['startDate']), day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.fromLTRB(16,24,16,24),
            child: GestureDetector(
              onTap: (){
                //여기에 월 선택
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                      text: TextSpan(
                          text: 'MY ',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: DateFormat('M월').format(_selectedDay),
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                                text: ' 일정',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            )
                          ]
                      )
                  ),
                  NadalIconButton(icon: BootstrapIcons.calendar2_plus, onTap: (){
                    context.push('/create/schedule', extra: ScheduleParams(date: _selectedDay));
                  })
                ],
              ),
            ) 
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TableCalendar(
            locale: 'ko_KR',
            focusedDay: _focusedDay,
            currentDay: _selectedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 1000)),
            lastDay: DateTime.now().add(const Duration(days: 1000)),
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            onPageChanged: (dateTime){
              setState(() {
                _focusedDay = dateTime;
                _selectedDay = dateTime;
              });
              userProvider.fetchMySchedules(dateTime);
            },

            headerVisible: false,

            calendarBuilders: CalendarBuilders(
              //요일 설정
              dowBuilder: (context, day){
                final text = TextFormManager.returnWeek(date: day);
                return Center(
                  child: FittedBox(
                    child: Text(text , style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: day.weekday == 6 ? Colors.blueAccent : day.weekday == 7 ? Colors.redAccent :
                     Theme.of(context).colorScheme.onSurface)),
                  ),
                );
              },

                //선택한 날짜 스타일
                selectedBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day, userProvider.schedules);
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
                    padding: EdgeInsets.symmetric(horizontal: 3),
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
                final events = _getEventsForDay(day, userProvider.schedules);
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
                              child: Text(events.first['title'], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w800, fontSize: 10),),
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
                final events = _getEventsForDay(day, userProvider.schedules);
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
                                  child: Text(events.first['title'], style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xfff1f1f1),overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w800, fontSize: 10),),
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
        ),
        Divider(),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //연도가 달라지면 연표기
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('${DateFormat(
                      _selectedDay.year != DateTime.now().year ?
                      'yyyy년 M월 d일' : 'M월 d일'
                  ).format(_selectedDay)} (${TextFormManager.returnWeek(date: _selectedDay)})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),),
                ),
                SizedBox(height: 16.h,),
                if(_getEventsForDay(_selectedDay, userProvider.schedules).isNotEmpty)
                ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _getEventsForDay(_selectedDay, userProvider.schedules).length,
                    itemBuilder: (context, index){
                      final schedule = _getEventsForDay(_selectedDay, userProvider.schedules)[index];
                      return NadalSimpleScheduleList(schedule: schedule);
                    })
                else
                  SizedBox(
                    height: 230,
                    child: NadalEmptyList(title: '이 날은 아직 비어 있어요', subtitle: '일정을 하나 추가해볼까요?', onAction: (){
                      context.push('/create/schedule', extra: ScheduleParams(date: _selectedDay));
                    },actionText: '일정 추가하기',),
                  )
              ],
            ),
        )
      ],
    );
  }
}
