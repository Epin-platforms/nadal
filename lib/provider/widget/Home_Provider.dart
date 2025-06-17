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
    try {
      final res = await serverManager.get('app/banner/more');
      if(res.statusCode == 200){
        final data = List.from(res.data);

        if(data.isNotEmpty){
          _morePageBanner = res.data;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ 더보기 배너 로드 실패: $e');
    }
  }

  ///
  /// 번개챗
  ///
  final List<String> _quickChatMenu = ['내 번개챗', '대회', '둘러보기'];
  List<String> get quickChatMenu => _quickChatMenu;

  int _currentMenu = 0;
  int get currentMenu => _currentMenu;

  void setMenu(int index){
    if(_currentMenu != index){
      _currentMenu = index;
      notifyListeners();
    }
  }

  // 🔧 로컬 퀵챗 관리 개선
  int _localQuickChatRoomsOffset = 0;
  bool _localQuickChatRoomsHasMore = true;
  bool _fetchingQuickChat = false;
  bool _hasInitializedLocalQuickChat = false;

  List<Map<String, dynamic>>? _myLocalQuickChatRooms;
  List<Map<String, dynamic>>? get myLocalQuickChatRooms => _myLocalQuickChatRooms;

  // 🔧 초기화 여부 확인
  bool get hasInitializedLocalQuickChat => _hasInitializedLocalQuickChat;

  // 🔧 로컬 퀵챗 최초 초기화
  Future<void> initializeLocalQuickChatRooms() async {
    if (_hasInitializedLocalQuickChat) {
      debugPrint('🔄 로컬 퀵챗이 이미 초기화됨 - 스킵');
      return;
    }

    try {
      debugPrint('🚀 로컬 퀵챗 최초 초기화 시작');
      _localQuickChatRoomsOffset = 0;
      _localQuickChatRoomsHasMore = true;
      _myLocalQuickChatRooms = null;

      await fetchMyLocalQuickChatRooms();
      _hasInitializedLocalQuickChat = true;

      debugPrint('✅ 로컬 퀵챗 최초 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 퀵챗 최초 초기화 실패: $e');
      _myLocalQuickChatRooms = [];
      _hasInitializedLocalQuickChat = true;
      notifyListeners();
    }
  }

  // 🔧 개선된 로컬 퀵챗 페치 메서드
  Future<void> fetchMyLocalQuickChatRooms() async{
    if (!_localQuickChatRoomsHasMore || _fetchingQuickChat) {
      debugPrint('⚠️ 로컬 퀵챗 페치 스킵: hasMore=$_localQuickChatRoomsHasMore, fetching=$_fetchingQuickChat');
      return;
    }

    try{
      _fetchingQuickChat = true;
      debugPrint('📥 로컬 퀵챗 페치 시작: offset=$_localQuickChatRoomsOffset');

      final res = await serverManager.get('room/my-local-quick?offset=$_localQuickChatRoomsOffset');

      if(res.statusCode == 200){
        final list = List<Map<String, dynamic>>.from(res.data);
        debugPrint('📊 로컬 퀵챗 ${list.length}개 로드됨');

        if(list.length < 10){
          _localQuickChatRoomsHasMore = false;
          debugPrint('📋 로컬 퀵챗 더 이상 없음');
        }else{
          _localQuickChatRoomsOffset++;
        }

        _myLocalQuickChatRooms ??= [];
        _myLocalQuickChatRooms!.addAll(list);

        // 🔧 중복 제거
        _removeDuplicateRooms();

        debugPrint('✅ 로컬 퀵챗 페치 완료: 총 ${_myLocalQuickChatRooms!.length}개');
      } else {
        debugPrint('❌ 로컬 퀵챗 페치 실패: ${res.statusCode}');
        _myLocalQuickChatRooms ??= [];
      }

      notifyListeners();
    }catch(error){
      debugPrint('❌ 로컬 퀵챗 페치 오류: $error');
      _myLocalQuickChatRooms ??= [];
      notifyListeners();
    } finally {
      _fetchingQuickChat = false;
    }
  }

  // 🔧 중복 방 제거
  void _removeDuplicateRooms() {
    if (_myLocalQuickChatRooms == null) return;

    final seenIds = <int>{};
    _myLocalQuickChatRooms!.removeWhere((room) {
      final roomId = room['roomId'] as int?;
      if (roomId == null || seenIds.contains(roomId)) {
        return true;
      }
      seenIds.add(roomId);
      return false;
    });
  }

  // 🔧 참가한 방 체크 및 제거 (개선)
  void checkExistRoom(int roomId){
    try {
      final roomsProvider = AppRoute.context?.read<RoomsProvider>();
      if (roomsProvider?.quickRooms?.containsKey(roomId) == true) {
        if (_myLocalQuickChatRooms != null) {
          final index = _myLocalQuickChatRooms!.indexWhere((e) => e['roomId'] == roomId);
          if (index != -1) {
            _myLocalQuickChatRooms!.removeAt(index);
            debugPrint('🗑️ 참가한 방 제거: $roomId');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 방 존재 체크 오류: $e');
    }
  }

  // 🔧 로컬 퀵챗 새로고침
  Future<void> refreshLocalQuickChatRooms() async {
    try {
      debugPrint('🔄 로컬 퀵챗 새로고침 시작');

      _localQuickChatRoomsOffset = 0;
      _localQuickChatRoomsHasMore = true;
      _myLocalQuickChatRooms = null;

      await fetchMyLocalQuickChatRooms();

      debugPrint('✅ 로컬 퀵챗 새로고침 완료');
    } catch (e) {
      debugPrint('❌ 로컬 퀵챗 새로고침 실패: $e');
    }
  }

  ///
  /// 둘러보기 페이지 보기
  ///
  List<Map<String, dynamic>>? _hotQuickChatRooms;
  List<Map<String, dynamic>>?  get hotQuickChatRooms => _hotQuickChatRooms;

  bool _hotLoading = false;

  Future<void> fetchHotQuickChatRooms() async{ //핫 퀵 룸은 총 4개만 불러오기
    if(_hotLoading) return;

    try {
      _hotLoading = true;
      debugPrint('🔥 핫 퀵챗 로드 시작');

      final res = await serverManager.get('room/hot-quick-rooms');

      if(res.statusCode == 200){
        final list = List<Map<String, dynamic>>.from(res.data);
        _hotQuickChatRooms = list;
        debugPrint('✅ 핫 퀵챗 ${list.length}개 로드 완료');
      } else {
        debugPrint('❌ 핫 퀵챗 로드 실패: ${res.statusCode}');
        _hotQuickChatRooms = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ 핫 퀵챗 로드 오류: $e');
      _hotQuickChatRooms = [];
      notifyListeners();
    } finally {
      _hotLoading = false;
    }
  }

  List<Map<String, dynamic>> _ranking = [];
  List<Map<String, dynamic>> get ranking => _ranking;

  Future<void> fetchRanking() async{
    if(_ranking.length == 3) {
      debugPrint('🏆 랭킹이 이미 로드됨 - 스킵');
      return; //이미 지정되면 더이상 불러오지 않음 재시작하면 달라짐
    }

    try {
      debugPrint('🏆 랭킹 로드 시작');

      final res = await serverManager.get('app/ranking');
      if(res.statusCode == 200){
        final list = List<Map<String, dynamic>>.from(res.data);
        _ranking = list;
        debugPrint('✅ 랭킹 ${list.length}개 로드 완료');
        notifyListeners();
      } else {
        debugPrint('❌ 랭킹 로드 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 랭킹 로드 오류: $e');
    }
  }

  //
  // 친구 위젯 관리
  //
  final _friendMenu = ['내 친구', '친구 요청 사용자'];
  int _currentFriendMenu = 0;

  List<String> get friendMenu => _friendMenu;
  int get currentFriendMenu => _currentFriendMenu;

  void setFriendMenu(int index){
    if(index != _currentFriendMenu){
      _currentFriendMenu = index;
      notifyListeners();
    }
  }

  // 🔧 디버깅 정보
  void printDebugInfo() {
    debugPrint('📊 HomeProvider 상태:');
    debugPrint('- 현재 탭: $_currentTab');
    debugPrint('- 현재 퀵챗 메뉴: $_currentMenu');
    debugPrint('- 로컬 퀵챗 초기화됨: $_hasInitializedLocalQuickChat');
    debugPrint('- 로컬 퀵챗 개수: ${_myLocalQuickChatRooms?.length ?? 0}');
    debugPrint('- 핫 퀵챗 개수: ${_hotQuickChatRooms?.length ?? 0}');
    debugPrint('- 랭킹 개수: ${_ranking.length}');
  }

  // 🔧 상태 리셋 (필요시)
  void resetLocalQuickChatState() {
    _localQuickChatRoomsOffset = 0;
    _localQuickChatRoomsHasMore = true;
    _fetchingQuickChat = false;
    _hasInitializedLocalQuickChat = false;
    _myLocalQuickChatRooms = null;
    debugPrint('🔄 로컬 퀵챗 상태 리셋 완료');
  }
}