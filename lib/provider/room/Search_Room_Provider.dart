import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/form/widget/Text_Form_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SearchMode{
  recently, auto, result
}

class SearchRoomProvider extends ChangeNotifier{
  SearchMode _mode = SearchMode.recently;
  SearchMode get mode => _mode;

  onChangedMode(SearchMode value){
    if(_mode != value){
      _mode = value;
      notifyListeners();
    }
  }

  late final SharedPreferences prefs;
  final _recentlySearchKey = "epin.nadal.rooms_search_key";

  List<String> get recentlySearch => _recentlySearch;
  List<Map> get recommendRooms => _recommendRooms;

  Map<String, List<Map>> get searchResults => _searchResults;
  List<Map> get resultRooms => searchResults[_lastSearch] ?? [];
  List<String> get autoTextSearch => _autoTextSearch;

  List<String> _recentlySearch  = [];
  List<Map> _recommendRooms = []; //추천
  Map<String, List<Map>> _searchResults = {};
  List<String> _autoTextSearch = [];

  SearchRoomProvider(Map user){
    _getRecentlySearch();
    fetchRecommendRoom(user);
    _searchController = TextEditingController();
    _searchNode = FocusNode();

    _searchController.addListener(_modeLister);
    _searchController.addListener(_onSearchChanged);
    _searchNode.addListener(_modeLister);
  }

  fetchRecommendRoom(Map user) async{
    final res = await serverManager.get('room/recommend?local=${user['local']}');

    if(res.statusCode == 200){
      _recommendRooms = List.from(res.data);
      notifyListeners();
    }
  }


  //최근 검색 목록 가져오기 //최초 프로바이더 만들때만 가져오기
  _getRecentlySearch() async{
    prefs = await SharedPreferences.getInstance();

    if(prefs.containsKey(_recentlySearchKey)){
      _recentlySearch = prefs.getStringList(_recentlySearchKey)!;
      notifyListeners();
    }
  }

  @override //꺼질떄 업데이트
  dispose(){
    _updateRecentlySearch();
    _searchController.removeListener(_modeLister);
    _searchController.removeListener(_onSearchChanged);
    _searchNode.removeListener(_modeLister);
    _searchController.dispose();
    _searchNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  //최근 검색목록 저장
  _updateRecentlySearch(){
    prefs.setStringList(_recentlySearchKey, _recentlySearch);
  }

  _addRecentlySearch(String value){
    if(_recentlySearch.contains(value)){ //가장 최근으로 업데이트
      _recentlySearch.remove(value);
      _recentlySearch.add(value);
    }else{
      _recentlySearch.add(value);
    }
    notifyListeners();
  }

  //사용자가 없에는 코드
  removeRecentlySearch(int index){
    _recentlySearch.removeAt(index);
    notifyListeners();
  }

  late final TextEditingController _searchController;
  late final FocusNode _searchNode;
  TextEditingController get searchController => _searchController;
  FocusNode get searchNode => _searchNode;


  _modeLister(){
    if (_searchController.text.isEmpty && resultRooms.isEmpty) {
      print("모드가 최근검색으로 변경됨");
      onChangedMode(SearchMode.recently);
    } else if (_searchNode.hasFocus) {
      print("모드가 자동검색으로 변경됨");
      onChangedMode(SearchMode.auto);
    } else {
      print("모드가 결과로 변경됨");
      onChangedMode(SearchMode.result);
    }
  }

  //자동완성 딜레이로 읽기
  Timer? _debounce;

  void _onSearchChanged() {
    if(_searchController.text.trim().length < 2) return;
    // 기존 타이머 있으면 취소
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 새 타이머 시작 (500ms 후 실행)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        searchAutoText();
      }
    });
  }


  searchAutoText() async{
    final res = await serverManager.get('room/autoText?text=${_searchController.text}');

    if(res.statusCode == 200){
      final data = extractAutoComplete(res.data);
      _autoTextSearch = List.from(data);
      notifyListeners();
    }
  }

  List<String> extractAutoComplete(List serverResult) {
    final Set<String> suggestions = {};

    for (final row in serverResult) {
      if (row['tagSnippet'] != null) {
        final tags = List<String>.from(row['tagSnippet']);
        suggestions.addAll(tags);
      }

      if (row['descriptionSnippet'] != null) {
        suggestions.add(row['descriptionSnippet']);
      }

      if (row['roomName'] != null) {
        suggestions.add(row['roomName']);
      }
    }

    return suggestions.toList();
  }

  //결과가져오기
  //결과를 가져왔는지 체크
  bool _submitted = false;
  bool get submitted => _submitted;

  String _lastSearch = '';
  String get lastSearch => _lastSearch;

  Map<String, int> _searchOffsets = {}; // key: 검색어, value: offset


  Future<void> onSubmit(String text) async {
    if(text.length < 2) return;

    if (_searchController.text != text) {
      _searchController.text = text;
    }

    _searchNode.unfocus();
    _submitted = false;
    _addRecentlySearch(text);

    final offset = _searchOffsets[text] ?? 0;
    final query = TextFormManager.encodeQueryParam(text);
    final res = await serverManager.get('room/search?text=$query&offset=$offset');

    if (res.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(res.data);

      // 기존 결과에 누적 저장
      final prev = _searchResults[text] ?? [];
      _searchResults[text] = [...prev, ...results];
      _searchOffsets[text] = offset + results.length;

      _lastSearch = text;
      _submitted = true;
      notifyListeners();
    }
  }

}