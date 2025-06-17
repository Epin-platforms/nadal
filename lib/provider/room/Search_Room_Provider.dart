import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/form/widget/Text_Form_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SearchMode { recently, auto, result }

class SearchRoomProvider extends ChangeNotifier {
  SearchMode _mode = SearchMode.recently;
  SearchMode get mode => _mode;

  late final SharedPreferences _prefs;
  late String _recentlySearchKey;
  static const int _maxRecentSearches = 10;

  // Getters
  List<String> get recentlySearch => List.unmodifiable(_recentlySearch);
  Map<String, List<Map>> get searchResults => Map.unmodifiable(_searchResults);
  List<Map> get resultRooms => _searchResults[_lastSearch] ?? [];
  List<String> get autoTextSearch => List.unmodifiable(_autoTextSearch);
  bool get isOpen => _isOpen;
  bool get submitted => _submitted;
  String get lastSearch => _lastSearch;
  TextEditingController get searchController => _searchController;
  FocusNode get searchNode => _searchNode;

  // Private fields
  List<String> _recentlySearch = [];
  Map<String, List<Map>> _searchResults = {};
  List<String> _autoTextSearch = [];
  late final bool _isOpen;
  bool _submitted = false;
  String _lastSearch = '';
  Map<String, int> _searchOffsets = {};
  late final TextEditingController _searchController;
  late final FocusNode _searchNode;
  Timer? _debounce;

  SearchRoomProvider(Map user, bool isOpen) {
    _isOpen = isOpen;
    _recentlySearchKey = _isOpen ? "epin.nadal.rooms_search_key.open" : "epin.nadal.rooms_search_key.club";
    _initializeControllers();
    _getRecentlySearch();
  }

  void _initializeControllers() {
    _searchController = TextEditingController();
    _searchNode = FocusNode();
    _searchController.addListener(_onSearchTextChanged);
    _searchNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _updateRecentlySearch();
    _cleanupControllers();
    _debounce?.cancel();
    super.dispose();
  }

  void _cleanupControllers() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchNode.dispose();
  }

  // Mode management
  void _onFocusChanged() {
    _updateMode();
  }

  void _onSearchTextChanged() {
    _updateMode();
    _handleAutoComplete();
  }

  void _updateMode() {
    final newMode = _determineMode();
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  SearchMode _determineMode() {
    if (_searchController.text.isEmpty && resultRooms.isEmpty) {
      return SearchMode.recently;
    } else if (_searchNode.hasFocus && _searchController.text.isNotEmpty) {
      return SearchMode.auto;
    } else {
      return SearchMode.result;
    }
  }

  // Recent search management
  Future<void> _getRecentlySearch() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final searches = _prefs.getStringList(_recentlySearchKey);
      if (searches != null) {
        _recentlySearch = searches;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('최근 검색 목록 로드 실패: $e');
    }
  }

  void _updateRecentlySearch() {
    try {
      _prefs.setStringList(_recentlySearchKey, _recentlySearch);
    } catch (e) {
      debugPrint('최근 검색 목록 저장 실패: $e');
    }
  }

  void _addRecentlySearch(String value) {
    // 단순한 검증만 (길이와 빈 값만 체크)
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    final normalizedValue = TextFormManager.normalizeText(trimmed);

    // 기존 항목 제거 후 최신으로 추가
    _recentlySearch.remove(normalizedValue);
    _recentlySearch.add(normalizedValue);

    // 최대 개수 제한
    if (_recentlySearch.length > _maxRecentSearches) {
      _recentlySearch.removeRange(0, _recentlySearch.length - _maxRecentSearches);
    }

    notifyListeners();
  }

  void removeRecentlySearch(int index) {
    if (index >= 0 && index < _recentlySearch.length) {
      _recentlySearch.removeAt(index);
      _updateRecentlySearch(); // SharedPreferences에도 반영
      notifyListeners();
    }
  }

  // Auto-complete handling
  void _handleAutoComplete() {
    final text = _searchController.text.trim();
    if (text.length < 2) {
      _autoTextSearch.clear();
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim() == text) {
        _searchAutoText(text);
      }
    });
  }

  Future<void> _searchAutoText(String text) async {
    // 기본적인 검증만 (서버에서 추가 검증 처리)
    final trimmed = text.trim();
    if (trimmed.length < 2) return;

    try {
      final normalizedText = TextFormManager.normalizeText(trimmed);
      final queryToInt = _isOpen ? 1 : 0;
      final encodedText = Uri.encodeComponent(normalizedText);

      final res = await serverManager.get(
          'room/autoText?isOpen=$queryToInt&text=$encodedText'
      );

      if (res.statusCode == 200 && mounted) {
        final data = _extractAutoComplete(res.data);
        _autoTextSearch = data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('자동완성 검색 실패: $e');
      _autoTextSearch.clear();
      if (mounted) notifyListeners();
    }
  }

  List<String> _extractAutoComplete(dynamic serverResult) {
    if (serverResult == null) return [];

    try {
      final List<dynamic> results = serverResult is List ? serverResult : [];
      final Set<String> suggestions = {};

      for (final row in results) {
        if (row is! Map) continue;

        // 태그 처리
        final tagSnippet = row['tagSnippet'];
        if (tagSnippet is List) {
          for (final tag in tagSnippet) {
            if (tag is String && tag.isNotEmpty) {
              suggestions.add(tag);
            }
          }
        }

        // 설명 처리
        final descriptionSnippet = row['descriptionSnippet'];
        if (descriptionSnippet is String && descriptionSnippet.isNotEmpty) {
          suggestions.add(descriptionSnippet);
        }

        // 방 이름 처리
        final roomName = row['roomName'];
        if (roomName is String && roomName.isNotEmpty) {
          suggestions.add(roomName);
        }
      }

      return suggestions.take(10).toList(); // 최대 10개로 제한
    } catch (e) {
      debugPrint('자동완성 데이터 추출 실패: $e');
      return [];
    }
  }

  // Search execution (검증 로직 단순화)
  Future<void> onSubmit(String text) async {
    final trimmed = text.trim();

    // 매우 기본적인 검증만 (길이만 체크)
    if (trimmed.isEmpty || trimmed.length < 2) {
      debugPrint('검색어가 너무 짧습니다: $trimmed');
      return;
    }

    final normalizedText = TextFormManager.normalizeText(trimmed);

    // UI 업데이트
    if (_searchController.text != normalizedText) {
      _searchController.text = normalizedText;
    }
    _searchNode.unfocus();

    // 상태 초기화
    _submitted = false;
    _addRecentlySearch(normalizedText);

    try {
      await _executeSearch(normalizedText);
    } catch (e) {
      debugPrint('검색 실행 실패: $e');
      if (mounted) {
        _submitted = true;
        notifyListeners();
      }
    }
  }

  Future<void> _executeSearch(String text) async {
    final offset = _searchOffsets[text] ?? 0;
    final encodedText = Uri.encodeComponent(text);
    final queryToInt = _isOpen ? 1 : 0;

    debugPrint('검색 실행: $text (인코딩: $encodedText)');

    final res = await serverManager.get(
        'room/search?text=$encodedText&offset=$offset&isOpen=$queryToInt'
    );

    debugPrint('검색 응답: ${res.statusCode}');

    if (res.statusCode == 200 && mounted) {
      final results = _parseSearchResults(res.data);

      debugPrint('검색 결과 개수: ${results.length}');

      // 기존 결과에 누적
      final prevResults = _searchResults[text] ?? [];
      _searchResults[text] = [...prevResults, ...results];
      _searchOffsets[text] = offset + results.length;

      _lastSearch = text;
      _submitted = true;
      notifyListeners();
    } else {
      debugPrint('검색 실패: 상태코드 ${res.statusCode}');
    }
  }

  List<Map<String, dynamic>> _parseSearchResults(dynamic data) {
    if (data == null) return [];

    try {
      if (data is List) {
        return data
            .where((item) => item is Map)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('검색 결과 파싱 실패: $e');
      return [];
    }
  }

  // Helper for checking if widget is still mounted
  bool get mounted => !(_searchController.hasListeners == false);
}