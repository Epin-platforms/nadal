import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/league/League_Model.dart';

import '../../util/item/List_Package.dart';

class LeagueProvider extends ChangeNotifier{

  LeagueProvider(){
    fetchLeague();
  }

  List<LeagueModel>? _leagues;
  List<LeagueModel>? get leagues => _leagues;

  bool _hasMore = false;
  bool _loading = false;

  fetchLeague() async{
    if(leagues != null && leagues!.isEmpty || _hasMore || _loading) return; //만약 호출했는데 이미 비어있다면 종료
    _loading = true;
    final lastLeagueId =  _leagues?.lastOrNull?.leagueId;
    final queryStr = lastLeagueId == null ? '/app/league' : '/app/league?lastLeagueId=$lastLeagueId';

    try{
      final res = await serverManager.get(queryStr);

      if(res.statusCode == 200){
        _leagues ??= [];
        final list = List<LeagueModel>.from(res.data.map((e)=> LeagueModel.fromJson(e)));
        _leagues!.addAll(list);

        if(list.length < 20){
          _hasMore = true;
        }
      }
    }finally{
      _loading = false;
      notifyListeners();
    }
  }

  // 필터링된 대회 목록 가져오기
  final List<String> _locals = ['전체', ...ListPackage.local.keys];
  List<String> get locals => _locals;
  String _selectedLocal = '전체';
  String get selectedLocal => _selectedLocal;

  List<LeagueModel> get filteredLeagues {
    if (_selectedLocal == '전체') {
      return leagues!;
    } else {
      return leagues!.where((league) =>
          _selectedLocal.contains(league.local)).toList();
    }
  }

  setSelectLocal(int index){
    if(_selectedLocal != _locals[index]){
      _selectedLocal = _locals[index];
      notifyListeners();
    }
  }
}