import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/league/League_Model.dart';

class LeagueProvider extends ChangeNotifier{

  LeagueProvider(){
    fetchLeague();
  }

  List<LeagueModel>? _leagues;
  List<LeagueModel>? get leagues => _leagues;

  bool _hasMore = false;
  bool _loading = false;
  bool get loading => _loading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // 서버 검색 지원 여부 (서버 API 수정 완료)
  bool _serverSearchSupported = true;

  // 검색 모드인지 확인
  bool get isSearchMode => _searchQuery.isNotEmpty;

  fetchLeague() async{
    if(_loading) return;

    // 검색 모드가 아닐 때만 페이지네이션 체크
    if(!isSearchMode && (_leagues != null && _leagues!.isEmpty || _hasMore)) return;

    _loading = true;

    try{
      String queryStr;

      if(isSearchMode) {
        // 서버 검색 모드: 검색어와 함께 요청
        final lastLeagueId = _leagues?.lastOrNull?.leagueId;
        queryStr = lastLeagueId == null
            ? '/app/league?search=${Uri.encodeComponent(_searchQuery)}'
            : '/app/league?search=${Uri.encodeComponent(_searchQuery)}&lastLeagueId=$lastLeagueId';
      } else {
        // 일반 모드: 기존 페이지네이션
        final lastLeagueId = _leagues?.lastOrNull?.leagueId;
        queryStr = lastLeagueId == null ? '/app/league' : '/app/league?lastLeagueId=$lastLeagueId';
      }

      final res = await serverManager.get(queryStr);

      if(res.statusCode == 200){
        _leagues ??= [];
        final list = List<LeagueModel>.from(res.data.map((e)=> LeagueModel.fromJson(e)));
        _leagues!.addAll(list);

        // 20개 미만이면 더 이상 데이터가 없음
        if(list.length < 20){
          _hasMore = true;
        } else {
          _hasMore = false;
        }
      }
    } catch(e) {
      print('대회 데이터 로딩 오류: $e');
    } finally{
      _loading = false;
      notifyListeners();
    }
  }

  // 검색 기능 - 서버에서 새로운 데이터 가져오기
  void setSearchQuery(String query) async {
    if (_searchQuery == query.trim()) return;

    _searchQuery = query.trim();

    // 기존 데이터 초기화
    _leagues = null;
    _hasMore = false;

    // 새로운 검색 또는 전체 목록 요청
    await fetchLeague();
  }

  // 검색 초기화
  void clearSearch() async {
    if (_searchQuery.isEmpty) return;

    _searchQuery = '';
    _leagues = null;
    _hasMore = false;

    // 전체 목록 다시 로드
    await fetchLeague();
  }

  // 서버에서 이미 필터링된 결과 반환
  List<LeagueModel> get filteredLeagues {
    return _leagues ?? [];
  }

  // 페이지네이션을 위한 추가 데이터 로드
  void loadMore() {
    if (!_loading && !_hasMore) {
      fetchLeague();
    }
  }
}