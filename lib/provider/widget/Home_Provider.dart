import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
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

  Future<void> _fetchMorePageBanner() async{
    final res = await serverManager.get('app/banner/more');
    if(res.statusCode == 200){
      final data = List.from(res.data);

      if(data.isNotEmpty){
        _morePageBanner = res.data;
        notifyListeners();
      }
    }
  }

  ///
  /// 번개챗
  ///
  final List<String> _quickChatMenu = ['내 채팅', '둘러보기'];
  List<String> get quickChatMenu => _quickChatMenu;

  int _currentMenu = 0;
  int get currentMenu => _currentMenu;

  void setMenu(int index){
    if(_currentMenu != index){
      _currentMenu = index;
      notifyListeners();
    }
  }

  int _localQuickChatRoomsOffset = 0;
  bool _localQuickChatRoomsHasMore = true;
  bool _fetchingQuickChat = false;

  List<Map<String, dynamic>>? _myLocalQuickChatRooms;
  List<Map<String, dynamic>>? get myLocalQuickChatRooms => _myLocalQuickChatRooms;

  void fetchMyLocalQuickChatRooms() async{
    try{
      print("번개챗 패치시작");
      if(!_localQuickChatRoomsHasMore || _fetchingQuickChat) return;
      _fetchingQuickChat = true;
      final res = await serverManager.get('room/my-local-quick?offset=$_localQuickChatRoomsOffset');
      if(res.statusCode == 200){
        print('번개챗 받아온 결과 ${res.data}');
        final list = List<Map<String, dynamic>>.from(res.data);

        if(list.length < 10){
          _localQuickChatRoomsHasMore = false;
        }else{
          _localQuickChatRoomsOffset++;
        }
        _myLocalQuickChatRooms ??= [];
        if(_myLocalQuickChatRooms != null){
          print('번개챗에서 받아온 널 제거');
          _myLocalQuickChatRooms!.addAll(list);
        }
      }

      _fetchingQuickChat = false;
      notifyListeners();
    }catch(error){
      print(error);
      _myLocalQuickChatRooms = [];
      notifyListeners();
    }
  }
}