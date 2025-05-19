import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../form/widget/Text_Form_Manager.dart';

class DateTimePicker extends StatefulWidget {
  const DateTimePicker({super.key, required this.date, required this.visibleTime});
  final DateTime date;
  final bool visibleTime;
  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  final totalH = 12;
  final totalM = 60;
  late final FixedExtentScrollController hourController;
  late final FixedExtentScrollController minuteController;
  late PageController _isAMSelect;
  late DateTime selectDate;
  late DateTime focusDate;
  late bool isAM;
  late int hour;
  late int minute;


  @override
  void initState() {
    final dateForm = DateFormat('yyyy.MM.dd.HH.mm').format(widget.date).split('.');

    selectDate = DateTime(int.parse(dateForm[0]),int.parse(dateForm[1]),int.parse(dateForm[2]));
    focusDate = widget.date;
    isAM =  int.parse(dateForm[3]) < 12;
    _isAMSelect =  PageController(viewportFraction: 0.3, initialPage: isAM ? 0 : 1);
    hour = int.parse(dateForm[3]) == 0 ? 12 : int.parse(dateForm[3]) > 12 ? int.parse(dateForm[3]) - 12 : int.parse(dateForm[3]);
    hourController = FixedExtentScrollController(initialItem: 48000 + (hour - 1));
    minute = int.parse(dateForm[4]);
    minuteController = FixedExtentScrollController(initialItem: 60000 + minute);
    super.initState();
  }

  void createDate(){
    if(isAM && hour == 12){
      hour = 0;
    }else if(!isAM && hour != 12){
      hour += 12;
    }
    final date = DateTime(selectDate.year, selectDate.month, selectDate.day, hour, minute);
    Navigator.of(context).pop(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: FadeInUp(
        from: 8,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.now().subtract(const Duration(days: 100)),
                  lastDay: DateTime.now().add(const Duration(days: 100)),
                  focusedDay: focusDate,
                  currentDay: selectDate,
                  calendarFormat: CalendarFormat.month,

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      selectDate = selectedDay;
                      focusedDay = focusedDay;
                    });
                  },

                  rowHeight: 50,
                  headerStyle:  HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      leftChevronVisible: true,
                      leftChevronIcon: Icon(CupertinoIcons.chevron_back, size: 15, color: Theme.of(context).colorScheme.onSurface,),
                      rightChevronIcon: Icon(CupertinoIcons.chevron_forward, size: 15, color: Theme.of(context).colorScheme.onSurface,),
                      rightChevronVisible: true
                  ),

                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day){
                      final text = TextFormManager.returnWeek(date: day);
                      return Center(
                        child: FittedBox(
                          child: Text(text ,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: day.weekday == 6 ? Colors.blueAccent : day.weekday == 7 ? Colors.redAccent : Theme.of(context).colorScheme.onSurface)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).focusColor,
              ),
              if(widget.visibleTime)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    child: Center(
                        child: Row(
                          children: [
                            Flexible(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                          top: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                        )
                                    ),
                                  ),
                                )
                            ),
                            Flexible(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                          top: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                        )
                                    ),
                                  ),
                                )
                            ),
                            Flexible(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                          top: BorderSide(
                                              color: Theme.of(context).highlightColor,
                                              width: 1.2
                                          ),
                                        )
                                    ),
                                  ),
                                )
                            )
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        Flexible(
                            child: PageView(
                              onPageChanged: (value){
                                if(value == 0){
                                  setState(() {
                                    isAM = true;
                                  });
                                }else{
                                  setState(() {
                                    isAM = false;
                                  });
                                }
                              },
                              controller: _isAMSelect,
                              scrollDirection: Axis.vertical,
                              children: [
                                Container(
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: Text('오전', style: TextStyle(fontSize: 15, color: isAM ? Theme.of(context).colorScheme.onSurface:  Theme.of(context).highlightColor,  fontWeight: isAM ? FontWeight.w600 : FontWeight.normal),),
                                ),
                                Container(
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: Text('오후', style: TextStyle(fontSize: 15, color: !isAM ? Theme.of(context).colorScheme.onSurface:  Theme.of(context).highlightColor,  fontWeight: !isAM ? FontWeight.w600 : FontWeight.normal),),
                                )
                              ],
                            )
                        ),
                        //시간
                        Flexible(
                          child: ListWheelScrollView.useDelegate(
                            controller: hourController,
                            itemExtent: 60,
                            diameterRatio: 1.5,
                            perspective: 0.005,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              final value = (index % 12) + 1;

                              if (hour == 11 && value == 12 && isAM) {
                                isAM = false;
                                _isAMSelect.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              } else if (hour == 12 && value == 11 && !isAM) {
                                isAM = true;
                                _isAMSelect.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              } else if (hour == 11 && value == 12 && !isAM) {
                                isAM = true;
                                _isAMSelect.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              } else if (hour == 12 && value == 11 && isAM) {
                                isAM = false;
                                _isAMSelect.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              }

                              hour = (index % totalH) + 1;

                              setState(() {}); // 👈 index를 12로 나눈 나머지 + 1
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 48000*2, // 무한처럼 보이게
                              builder: (context, index) {
                                final hourValue = (index % totalH) + 1; // 👈 1~12 반복
                                final isSelected = index == hourController.selectedItem;

                                return GestureDetector(
                                  onTap: () {
                                    if (!isSelected) {
                                      hourController.animateToItem(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: isSelected ? 15 : 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? Theme.of(context).colorScheme.onSurface: Theme.of(context).highlightColor,
                                    ),
                                    child: Center(child: Text('$hourValue')),
                                  ),
                                );
                              },
                            ),
                          )
                        ),
                        Flexible(
                            child: ListWheelScrollView.useDelegate(
                              controller: minuteController, // 분용 controller
                              itemExtent: 60,
                              diameterRatio: 1.5,
                              perspective: 0.005,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                minute = index % 60; // 0~59 순환

                                setState(() {});
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 120000, // 무한처럼 보이게
                                builder: (context, index) {
                                  final minuteValue = index % 60; // 0~59
                                  final isSelected = index == minuteController.selectedItem;

                                  return GestureDetector(
                                    onTap: () {
                                      if (!isSelected) {
                                        minuteController.animateToItem(
                                          index,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    },
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: isSelected ? 15 : 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? Theme.of(context).colorScheme.onSurface: Theme.of(context).highlightColor,
                                      ),
                                      child: Center(child: Text(minuteValue.toString().padLeft(2, '0'))),
                                      // 👆 padLeft로 1자리 분은 01, 02 이렇게 2자리로 표시
                                    ),
                                  );
                                },
                              ),
                            )
                        )
                      ],
                    ),
                  )
                ],
              ),

              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Flexible(
                        child: InkWell(
                          onTap: ()=> Navigator.of(context).pop(),
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).highlightColor
                            ),
                            alignment: Alignment.center,
                            child: Text('취소', style: TextStyle(fontSize: 15, color: const Color(0xff8d8d8d), fontWeight: FontWeight.w500),),
                          ),
                        )
                    ),
                    SizedBox(width: 8,),
                    Flexible(
                        child: InkWell(
                          onTap: (){
                            createDate();
                          },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.primary
                            ),
                            alignment: Alignment.center,
                            child: Text('확인', style: TextStyle(fontSize: 15, color: const Color(0xffffffff), fontWeight: FontWeight.w500),),
                          ),
                        )
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
