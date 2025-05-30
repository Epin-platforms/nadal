import 'package:dio/dio.dart';
import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/manager/server/Socket_Manager.dart';

enum ScheduleState {
  normal,     // 0: 일반 스케줄
  recruiting, // 1: 게임 모집중
  preparing,  // 2: 게임 준비중
  ongoing,    // 3: 게임 진행중
  completed   // 4: 게임 완료
}

enum GameType {
  kdkSingle,    // KDK 단식
  kdkDouble,    // KDK 복식
  tourSingle,   // 토너먼트 단식
  tourDouble    // 토너먼트 복식
}

class ScheduleProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final SocketManager _socket = SocketManager();

  // === Core Schedule Data ===
  int? _scheduleId;
  Map<String, dynamic>? _schedule;
  Map<String, dynamic>? _scheduleMembers;
  Map<String, List<dynamic>>? _teams;

  // === Game Specific Data ===
  Map<int, Map<String, dynamic>>? _gameTables;
  List<Map<String, dynamic>>? _gameResult;
  int _currentStateView = 0;
  bool _isGameInitialized = false;

  // === Tournament & bye 처리 ===
  int _totalSlots = 0; // 2의 배수로 계산된 총 슬롯 수
  final Set<String> _byePlayers = {};

  // === Court Input State ===
  int? _courtInputTableId;
  TextEditingController? _courtController;

  // === Loading & Error States ===
  bool _isLoading = false;
  String? _errorMessage;

  // === Getters ===
  Map<String, dynamic>? get schedule => _schedule;
  Map<String, dynamic>? get scheduleMembers => _scheduleMembers;
  Map<String, List<dynamic>>? get teams => _teams;
  Map<int, Map<String, dynamic>>? get gameTables => _gameTables;
  List<Map<String, dynamic>>? get gameResult => _gameResult;
  int get currentStateView => _currentStateView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get courtInputTableId => _courtInputTableId;
  TextEditingController? get courtController => _courtController;
  int get totalSlots => _totalSlots;
  List<String> get byePlayers => _byePlayers.toList();
  int get byeCount => _byePlayers.length;

  // === Computed Properties ===
  bool get isGameSchedule => _schedule?['tag'] == '게임';
  bool get isOwner => _schedule?['uid'] == _auth.currentUser?.uid;
  ScheduleState get currentState => ScheduleState.values[_schedule?['state'] ?? 0];

  GameType? get gameType {
    if (!isGameSchedule) return null;
    final isKDK = _schedule?['isKDK'] == 1;
    final isSingle = _schedule?['isSingle'] == 1;

    if (isKDK && isSingle) return GameType.kdkSingle;
    if (isKDK && !isSingle) return GameType.kdkDouble;
    if (!isKDK && isSingle) return GameType.tourSingle;
    return GameType.tourDouble;
  }

  bool get isTeamGame => gameType == GameType.tourDouble;

  // === Participant Counts ===

  /// 전체 참가자 수
  int get realMemberCount => _scheduleMembers?.length ?? 0;

  /// 필요한 bye 수
  int get requiredByeCount => _totalSlots - realMemberCount;

  /// 팀 수 계산
  int getTeamCount() {
    if (_teams != null) return _teams!.length;
    if (_scheduleMembers == null) return 0;
    final Set<String> teamNames = {};
    for (final member in _scheduleMembers!.values) {
      final teamName = member['teamName'];
      if (teamName != null && teamName.toString().isNotEmpty) {
        teamNames.add(teamName.toString());
      }
    }
    return teamNames.length;
  }

  // === Tournament slot 계산 ===

  int calculateTournamentSlots() {
    if (!isGameSchedule ||
        gameType == GameType.kdkSingle ||
        gameType == GameType.kdkDouble) {
      return realMemberCount;
    }
    final count = isTeamGame ? getTeamCount() : realMemberCount;
    if (count <= 1) return 2;
    return _getNextPowerOfTwo(count);
  }

  int _getNextPowerOfTwo(int number) {
    int power = 1;
    while (power < number) power <<= 1;
    return power;
  }

  // === bye 처리 ===

  /// 빈 슬롯의 인접 인덱스 플레이어를 bye 처리
  void _assignByes() {
    // 토너먼트가 아니면 bye 없음
    if (!isGameSchedule ||
        (gameType != GameType.tourSingle && gameType != GameType.tourDouble)) {
      _byePlayers.clear();
      return;
    }
    _byePlayers.clear();
    // 1라운드 슬롯 수
    _totalSlots = calculateTournamentSlots();

    // index -> uid 맵
    final Map<int, String> indexToUid = {};
    _scheduleMembers!.forEach((uid, data) {
      final idx = data['memberIndex'] as int?;
      if (idx != null) indexToUid[idx] = uid;
    });

    // 빈 인덱스 찾아서 adjacent 처리
    for (var i = 1; i <= _totalSlots; i++) {
      if (!indexToUid.containsKey(i)) {
        final adjacent = (i.isOdd) ? i + 1 : i - 1;
        final byeUid = indexToUid[adjacent];
        if (byeUid != null) _byePlayers.add(byeUid);
      }
    }
  }

  // === Initialization ===

  Future<void> initializeSchedule(int scheduleId) async {
    try {
      _setLoading(true);
      _clearError();
      _scheduleId = scheduleId;
      await _fetchScheduleData();
      if (isGameSchedule && _schedule != null) {
        await _initializeGameData();
      }
    } catch (e) {
      _setError('스케줄 초기화 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchScheduleData() async {
    final res = await serverManager.get('schedule/$_scheduleId');
    if (res.statusCode == 200) {
      _schedule = Map<String, dynamic>.from(res.data['schedule'] ?? {});
      if (_schedule == null) {
        _handleScheduleNotFound();
        return;
      }
      await _processScheduleMembers(res.data['members']);
      _checkRoomRedirect();
    } else {
      throw Exception('스케줄 데이터 로드 실패');
    }
  }

  void _handleScheduleNotFound() {
    AppRoute.context?.pop();
    AppRoute.context
        ?.read<UserProvider>()
        .fetchMySchedules(DateTime.now(), force: true, reFetch: true);
    DialogManager.showBasicDialog(
      title: '어라..?',
      content: '해당 스케줄을 찾을 수 없어요',
      confirmText: '확인',
    );
  }

  Future<void> _processScheduleMembers(List? members) async {
    if (members == null) return;
    _scheduleMembers = {
      for (final m in members)
        if (m['uid'] != null)
          m['uid'].toString(): Map<String, dynamic>.from(m)
    };
    // 토너먼트인 경우 슬롯 및 bye 처리
    if (isGameSchedule &&
        (gameType == GameType.tourSingle || gameType == GameType.tourDouble)) {
      _totalSlots = calculateTournamentSlots();
      _assignByes();
    }
    // 복식 토너먼트 팀 구성
    if (gameType == GameType.tourDouble) {
      _buildTeamData();
    }
  }

  void _buildTeamData() {
    if (_scheduleMembers == null) return;
    final Map<String, List<dynamic>> teamMap = {};
    _scheduleMembers!.forEach((uid, memberData) {
      final String? teamName = memberData['teamName'];
      if (teamName != null && teamName.isNotEmpty) {
        teamMap.putIfAbsent(teamName, () => []).add(memberData);
      }
    });
    _teams = teamMap;
  }

  void _checkRoomRedirect() {
    final roomId = _schedule?['roomId'];
    final currentUid = _auth.currentUser?.uid;
    if (roomId != null &&
        currentUid != null &&
        !_scheduleMembers!.containsKey(currentUid) &&
        AppRoute.context!.read<RoomsProvider>().rooms?.containsKey(roomId) ==
            false) {
      AppRoute.context?.pushReplacement('/room/preview/$roomId');
    }
  }

  Future<void> _initializeGameData() async {
    if (_isGameInitialized) return;
    try {
      _currentStateView = _schedule?['state'] ?? 0;
      if (currentState.index < ScheduleState.completed.index) {
        _setupGameSocketListeners(true);
        _socket.emit('joinGame', _scheduleId);
      }
      _isGameInitialized = true;
    } catch (e) {
      _setError('게임 초기화 실패: $e');
    }
  }

  // === Socket Management ===

  void _setupGameSocketListeners(bool enable) {
    if (enable) {
      _socket.on('changedState', _handleStateChange);
      _socket.on('refreshMember', _handleMemberRefresh);
      _socket.on('score', _handleScoreChange);
      _socket.on('court', _handleCourtChange);
      _socket.on('refreshGame', _handleGameRefresh);
    } else {
      _socket.off('changedState', _handleStateChange);
      _socket.off('refreshMember', _handleMemberRefresh);
      _socket.off('score', _handleScoreChange);
      _socket.off('court', _handleCourtChange);
      _socket.off('refreshGame', _handleGameRefresh);
    }
  }

  void _handleStateChange(dynamic data) {
    if (data['state'] != null) {
      _schedule?['state'] = data['state'];
      _currentStateView = data['state'];
      notifyListeners();
    }
  }

  bool indexing = false;

  void _handleMemberRefresh(dynamic data) async {
    indexing = true;
    notifyListeners();
    await updateMembers();
    indexing = false;
    notifyListeners();
  }

  void _handleScoreChange(dynamic data) {
    final tableId = data['tableId'];
    final score = data['score'];
    final where = data['where'];
    if (_gameTables?[tableId] != null) {
      _gameTables![tableId]!['score$where'] = score;
      notifyListeners();
    }
  }

  void _handleCourtChange(dynamic data) {
    final tableId = data['tableId'];
    final court = data['court'];
    if (_gameTables?[tableId] != null) {
      _gameTables![tableId]!['court'] = court;
      notifyListeners();
    }
  }

  void _handleGameRefresh(dynamic data) {
    fetchGameTables();
  }

  // === Schedule Operations ===

  Future<void> updateMembers() async {
    try {
      final scheduleId = _schedule?['scheduleId'];
      final useNickname = _schedule?['useNickname'] ?? 1;
      if (scheduleId == null) return;
      final res = await serverManager.get(
          'scheduleMember/$scheduleId?useNickname=$useNickname');
      if (res.statusCode == 200 && res.data is List) {
        await _processScheduleMembers(res.data);
        notifyListeners();
      }
    } catch (e) {
      _setError('멤버 업데이트 실패: $e');
    }
  }

  Map<String, dynamic>? getMemberData(String uid) {
    return _scheduleMembers?[uid];
  }

  Map<String, dynamic> getGameLimits() {
    final limits = <String, dynamic>{};
    switch (gameType) {
      case GameType.kdkSingle:
        limits['min'] = GameManager.min_kdk_single_member;
        limits['max'] = GameManager.max_kdk_single_member;
        limits['type'] = 'KDK 단식';
        break;
      case GameType.kdkDouble:
        limits['min'] = GameManager.min_kdk_double_member;
        limits['max'] = GameManager.max_kdk_double_member;
        limits['type'] = 'KDK 복식';
        break;
      case GameType.tourSingle:
        limits['min'] = GameManager.min_tour_single_member;
        limits['max'] = GameManager.max_tour_single_member;
        limits['type'] = '토너먼트 단식';
        break;
      case GameType.tourDouble:
        limits['min'] = GameManager.min_tour_double_member;
        limits['max'] = GameManager.max_tour_double_member;
        limits['type'] = '토너먼트 복식';
        limits['unit'] = '팀';
        break;
      default:
        limits['min'] = 4;
        limits['max'] = 16;
        limits['type'] = '일반';
    }
    return limits;
  }

  bool canParticipate() {
    final limits = getGameLimits();
    final currentCount = isTeamGame ? getTeamCount() : realMemberCount;
    return currentCount < limits['max'];
  }

  bool canStartGame() {
    final limits = getGameLimits();
    final currentCount = isTeamGame ? getTeamCount() : realMemberCount;
    return currentCount >= limits['min'] && currentCount <= limits['max'];
  }

  Future<String> participateSchedule() async {
    final validation = _validateParticipation();
    if (validation != 'ok') return validation;
    try {
      AppRoute.pushLoading();
      final data = {
        'scheduleId': _schedule!['scheduleId'],
        'gender': AppRoute.context?.read<UserProvider>().user?['gender']
      };
      await serverManager.post('schedule/participation', data: data);
      return 'complete';
    } catch (e) {
      return 'error';
    } finally {
      AppRoute.popLoading();
    }
  }

  String _validateParticipation() {
    final gender = AppRoute.context?.read<UserProvider>().user?['gender'];
    if (_schedule!['maleLimit'] != null && gender == 'M') {
      final limit = _schedule!['maleLimit'];
      final maleCount =
          _scheduleMembers!.values.where((e) => e['gender'] == 'M').length;
      if (limit <= maleCount) {
        DialogManager.errorHandler('남자 인원이 다 찼어요.');
        return 'maleLimit';
      }
    }
    if (_schedule!['femaleLimit'] != null && gender == 'F') {
      final limit = _schedule!['femaleLimit'];
      final femaleCount =
          _scheduleMembers!.values.where((e) => e['gender'] == 'F').length;
      if (limit <= femaleCount) {
        DialogManager.errorHandler('여자 인원이 다 찼어요.');
        return 'femaleLimit';
      }
    }
    if (isGameSchedule && !canParticipate()) {
      DialogManager.errorHandler('게임 인원이 다 찼어요.');
      return 'playerLimit';
    }
    return 'ok';
  }

  Future<String> participateTeamSchedule(int teamId) async {
    try {
      AppRoute.pushLoading();
      final data = {
        'scheduleId': _schedule!['scheduleId'],
        'teamId': teamId
      };
      final res =
      await serverManager.post('schedule/participation/team', data: data);
      if (res.statusCode == 204) return 'exist';
      return 'complete';
    } catch (e) {
      return 'error';
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> cancelParticipation() async {
    try {
      AppRoute.pushLoading();
      final res = await serverManager
          .delete('schedule/participationCancel/${_schedule!['scheduleId']}');
      if (res.statusCode == 200) {
        _scheduleMembers?.remove(_auth.currentUser!.uid);
        AppRoute.context
            ?.read<UserProvider>()
            .removeScheduleById(_schedule!['scheduleId']);
        notifyListeners();
      }
    } catch (e) {
      _setError('참가 취소 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> cancelTeamParticipation() async {
    try {
      AppRoute.pushLoading();
      final res = await serverManager
          .delete('schedule/participationCancel/team/${_schedule!['scheduleId']}');
      if (res.statusCode == 200) await updateMembers();
    } catch (e) {
      _setError('팀 참가 취소 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> memberParticipation(
      Map<String, dynamic> user, bool approval) async {
    try {
      final data = {
        'uid': user['uid'],
        'scheduleId': _schedule?['scheduleId'],
        'approval': approval,
        'gender': user['gender']
      };
      final res =
      await serverManager.put('scheduleMember/updateApproval', data: data);
      if (res.statusCode == 200) await updateMembers();
    } catch (e) {
      _setError('참가 승인/거절 실패: $e');
    }
  }

  Future<void> deleteSchedule() async {
    try {
      AppRoute.pushLoading();
      final res = await serverManager.delete('schedule/$_scheduleId');
      if (res.statusCode == 200) {
        AppRoute.context
            ?.read<UserProvider>()
            .removeScheduleById(_scheduleId!);
        AppRoute.context?.pop();
        DialogManager.showBasicDialog(
          title: '스케줄 삭제 완료!',
          content: '선택하신 스케줄을 깔끔하게 정리했어요.',
          confirmText: '확인',
        );
      }
    } catch (e) {
      _setError('스케줄 삭제 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  List<String> filterInviteAbleUsers(List<String> list) {
    if (scheduleMembers == null) return [];
    return list.where((e) => !scheduleMembers!.keys.contains(e)).toList();
  }

  // === Game Operations ===

  void setCurrentStateView(int state) {
    if (_currentStateView != state) {
      _currentStateView = state;
      notifyListeners();
    }
  }

  Future<void> changeGameState(int newState) async {
    try {
      AppRoute.pushLoading();
      await serverManager.put('game/state', data: {
        "scheduleId": _scheduleId,
        "state": newState
      });
    } catch (e) {
      _setError('게임 상태 변경 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> startGame() async {
    try {
      AppRoute.pushLoading();
      await serverManager.put('game/start/$_scheduleId');
    } catch (e) {
      _setError('게임 시작 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<Response?> updateMemberIndex(List<Map<String, dynamic>> members) async {
    try {
      AppRoute.pushLoading();
      final data = <String, dynamic>{'scheduleId': _scheduleId};
      for (int i = 0; i < members.length; i++) {
        data[members[i]['uid']] = i + 1;
      }
      return await serverManager.put('game/member/indexUpdate', data: data);
    } catch (e) {
      _setError('멤버 순서 업데이트 실패: $e');
      return null;
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<Response?> updateTeamIndex(List<Map<String, dynamic>> teamsList) async {
    try {
      AppRoute.pushLoading();
      final data = <String, dynamic>{'scheduleId': _scheduleId};
      for (int i = 0; i < teamsList.length; i++) {
        final team = teamsList[i];
        if (team['members'] != null) {
          for (var member in team['members']) {
            final uid = member['uid'];
            if (uid != null) data[uid] = i + 1;
          }
        }
      }
      return await serverManager.put('game/member/indexUpdate', data: data);
    } catch (e) {
      _setError('팀 순서 업데이트 실패: $e');
      return null;
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> createGameTable() async {
    try {
      AppRoute.pushLoading();
      String route;
      switch (gameType) {
        case GameType.kdkSingle:
          route = 'singleKDK';
          break;
        case GameType.kdkDouble:
          route = 'doubleKDK';
          break;
        case GameType.tourSingle:
          route = 'singleTournament';
          break;
        case GameType.tourDouble:
          route = 'doubleTournament';
          break;
        default:
          throw Exception('알 수 없는 게임 타입');
      }
      await serverManager.post(
          'game/createTable/$route', data: {'scheduleId': _scheduleId});
    } catch (e) {
      _setError('게임 테이블 생성 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> fetchGameTables() async {
    if (!isGameSchedule) return;
    try {
      final res = await serverManager.get('game/table/$_scheduleId');
      if (res.statusCode == 200) {
        final tables = List<Map<String, dynamic>>.from(res.data);
        _gameTables = {
          for (final table in tables) table['tableId'] as int: table,
        };
        notifyListeners();
      }
    } catch (e) {
      _setError('게임 테이블 로드 실패: $e');
    }
  }

  Future<void> fetchGameResult() async {
    if (!isGameSchedule) return;
    try {
      final res = await serverManager.get('game/result/$_scheduleId');
      if (res.statusCode == 200) {
        _gameResult = List<Map<String, dynamic>>.from(res.data);
        notifyListeners();
      }
    } catch (e) {
      _setError('게임 결과 로드 실패: $e');
    }
  }

  Future<void> updateScore(int tableId, int score, int where) async {
    try {
      final data = {
        'scheduleId': _scheduleId,
        'tableId': tableId,
        'score': score,
        'where': where
      };
      await serverManager.put('game/score', data: data);
    } catch (e) {
      _setError('점수 업데이트 실패: $e');
    }
  }

  Future<void> updateCourt(int tableId, String court) async {
    try {
      final data = {
        'scheduleId': _scheduleId,
        'tableId': tableId,
        'court': court
      };
      await serverManager.put('game/court', data: data);
    } catch (e) {
      _setError('코트 정보 업데이트 실패: $e');
    }
  }

  void setCourtInput(int? tableId) {
    _courtInputTableId = tableId;
    _courtController?.dispose();
    if (tableId == null) {
      _courtController = null;
    } else {
      _courtController = TextEditingController(
          text: _gameTables?[tableId]?['court'] ?? '');
    }
    notifyListeners();
  }

  Future<void> endGame() async {
    try {
      AppRoute.pushLoading();
      final finalScore = _schedule!['finalScore'];
      String endpoint;
      switch (gameType) {
        case GameType.kdkSingle:
          endpoint = 'game/end/singleKDK/$_scheduleId?finalScore=$finalScore';
          break;
        case GameType.kdkDouble:
          endpoint = 'game/end/doubleKDK/$_scheduleId?finalScore=$finalScore';
          break;
        case GameType.tourSingle:
          endpoint =
          'game/end/singleTournament/$_scheduleId?finalScore=$finalScore';
          break;
        case GameType.tourDouble:
          endpoint =
          'game/end/doubleTournament/$_scheduleId?finalScore=$finalScore';
          break;
        default:
          throw Exception('알 수 없는 게임 타입');
      }
      await serverManager.post(endpoint);
    } catch (e) {
      _setError('게임 종료 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> nextRound(int currentRound) async {
    try {
      AppRoute.pushLoading();
      await serverManager.put('game/nextRound', data: {
        'scheduleId': _scheduleId,
        'round': currentRound
      });
    } catch (e) {
      _setError('다음 라운드 진행 실패: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  // === Utility Methods ===

  List<MapEntry<int, Map<String, dynamic>>> getMyGames() {
    if (_gameTables == null) return [];
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    return _gameTables!.entries.where((entry) {
      final table = entry.value;
      return table['player1_0'] == uid ||
          table['player1_1'] == uid ||
          table['player2_0'] == uid ||
          table['player2_1'] == uid;
    }).toList();
  }

  String calculateEstimatedTime({
    required List<Map<String, dynamic>> members,
    required bool isSingles,
    int courts = 2,
  }) {
    int totalMatches = 0;
    final playerCount = members.length;
    if (isSingles) {
      totalMatches = (playerCount * (playerCount - 1)) ~/ 2;
    } else {
      totalMatches = playerCount.clamp(5, 16);
    }
    final minTimePerMatch = isSingles ? 0.75 : 1.0;
    final maxTimePerMatch = isSingles ? 1.25 : 1.5;
    final minTotalHours = (totalMatches * minTimePerMatch) / courts;
    final maxTotalHours = (totalMatches * maxTimePerMatch) / courts;
    final roundedMinHours =
    ((minTotalHours * 2).round() / 2).clamp(0.5, double.infinity);
    final ceilingMaxHours = maxTotalHours.ceil();
    if (roundedMinHours == ceilingMaxHours.toDouble()) {
      return '약 ${roundedMinHours.toStringAsFixed(roundedMinHours.truncateToDouble() == roundedMinHours ? 0 : 1)}시간';
    }
    return '약 ${roundedMinHours.toStringAsFixed(roundedMinHours.truncateToDouble() == roundedMinHours ? 0 : 1)}~${ceilingMaxHours}시간';
  }

  // === State Management ===

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      if (error != null) DialogManager.errorHandler(error);
      notifyListeners();
    }
  }

  void _clearError() {
    _setError(null);
  }

  // === Cleanup ===

  @override
  void dispose() {
    if (isGameSchedule && _isGameInitialized) {
      _setupGameSocketListeners(false);
      _socket.emit('leaveGame', _scheduleId);
    }
    _courtController?.dispose();
    super.dispose();
  }
}
