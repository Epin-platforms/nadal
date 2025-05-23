import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeProvider extends ChangeNotifier{

  HomeProvider(){
    _fetchMorePageBanner();
  }

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void onChangedTab(int tab){
    if(_currentTab != tab){
      _currentTab = tab;
      notifyListeners();
    }
  }

  //마이페이지 스크롤 컨트롤
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFormat get calendarFormat => _calendarFormat;

  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  DateTime? _selectedDay;
  DateTime? get selectedDay => _selectedDay;


  //더보기 페이지 배너 설정
  Map? _morePageBanner;
  Map? get morePageBanner => _morePageBanner;

  _fetchMorePageBanner() async{
    final res = await serverManager.get('app/banner/more');
    if(res.statusCode == 200){
      final data = List.from(res.data);

      if(data.isNotEmpty){
        _morePageBanner = res.data;
        notifyListeners();
      }
    }
  }
}