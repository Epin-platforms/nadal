import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:table_calendar/table_calendar.dart';

class RoomScheduleProvider extends ChangeNotifier{
  late final int roomId;

  List<Map>? _schedules;
  List<Map>? get schedules => _schedules;

  RoomScheduleProvider(this.roomId){
    final DateTime now = DateTime.now();
    fetchRoomSchedule(now);
  }

  Future<void> fetchRoomSchedule(DateTime date) async{
    final from = DateTime(date.year, date.month, 1).toIso8601String();
    final to = DateTime(date.year, date.month + 1, 0, 23, 59, 59).toIso8601String();

    final res = await serverManager.get('schedule/room/$roomId?from=$from&to=$to');

    _schedules = [];
    if(res.statusCode == 200){
      final newSchedules = List.from(res.data);
      final existingIds = _schedules!.map((e) => e['scheduleId']).toSet();
      final filtered = List<Map>.from(newSchedules.where((s) => !existingIds.contains(s['scheduleId'])));
      _schedules!.addAll(filtered);
      notifyListeners();
    }
    notifyListeners();
  }

  void updateSchedule({required int scheduleId}) async{
    if(schedules != null){ //널 방지
      final index = _schedules!.indexWhere((e)=> e['scheduleId'] == scheduleId);
      final schedule = _schedules![index];

      final response = await serverManager.get('schedule/update-where-room?updateAt=${schedule['updateAt']}&scheduleId=$scheduleId&scheduleMemberCount=${schedule['scheduleMemberCount']}');

      if(response.statusCode == 200){
        _schedules![index] = response.data;
        notifyListeners();
      }else if(response.statusCode == 202){
        _schedules!.removeAt(index);
        notifyListeners();
      }else if(response.statusCode == 203){
        _schedules![index]['scheduleMemberCount'] = response.data;
        notifyListeners();
      }
    }
  }

  //캘린더 위젯 조절
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();


  void setDate({required DateTime focusDay, required DateTime selectDay}){
    _focusedDay = focusDay;
    _selectedDay = selectDay;
    notifyListeners();
  }

  // 특정 날짜에 일정을 불러오는 함수
  List<Map> getEventsForDay(DateTime day) => schedules!.where((schedule) => isSameDay(DateTime.parse(schedule['startDate']), day)).toList();

}