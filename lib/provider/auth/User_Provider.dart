import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/auth/social/Apple_Manager.dart';
import 'package:my_sports_calendar/manager/auth/social/Google_Manager.dart';
import 'package:my_sports_calendar/manager/auth/social/Kakao_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/util/handler/Security_Handler.dart';
import '../../manager/project/Import_Manager.dart';

enum UserProviderState {
  none,
  loggedIn,
  loggedOut
}

class UserProvider extends ChangeNotifier {
  // ============================================
  // 상태 관리
  // ============================================
  UserProviderState _state = UserProviderState.none;
  UserProviderState get state => _state;

  final _auth = FirebaseAuth.instance;
  Map? _user;
  Map? get user => _user;

  bool _firstLoading = false;

  // ============================================
  // 스케줄 관리 (메모리 효율화)
  // ============================================
  final Map<String, List<Map>> _schedulesCache = {};
  final Set<String> _fetchedMonths = {};

  List<Map> get schedules {
    final allSchedules = <Map>[];
    for (final monthSchedules in _schedulesCache.values) {
      allSchedules.addAll(monthSchedules);
    }
    // 중복 제거 및 정렬
    final uniqueSchedules = <Map>[];
    final seenIds = <int>{};

    for (final schedule in allSchedules) {
      final id = schedule['scheduleId'] as int?;
      if (id != null && !seenIds.contains(id)) {
        seenIds.add(id);
        uniqueSchedules.add(schedule);
      }
    }

    uniqueSchedules.sort((a, b) {
      final aDate = DateTime.tryParse(a['startDate'] ?? '');
      final bDate = DateTime.tryParse(b['startDate'] ?? '');
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });

    return uniqueSchedules;
  }

  List<String> get fetchCached => _fetchedMonths.toList();

  // ============================================
  // 초기화
  // ============================================
  void userProviderInit() {
    _firebaseUserListener();
  }

  // ============================================
  // Firebase 사용자 상태 리스너
  // ============================================
  void _firebaseUserListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      try {
        if (user == null) {
          _handleLoggedOut();
        } else {
          await _handleLoggedIn();
        }
      } catch (e) {
        print('Firebase 상태 변경 처리 오류: $e');
        _handleError();
      }
    });
  }

  void _handleLoggedOut() {
    _state = UserProviderState.loggedOut;
    _user = null;
    _clearScheduleCache();
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoute.context != null) {
        AppRoute.context!.go('/login');
      }
    });
  }

  Future<void> _handleLoggedIn() async {
    await fetchUserData(loading: _firstLoading);
    _firstLoading = true;
  }

  void _handleError() {
    _state = UserProviderState.none;
    notifyListeners();
  }

  // ============================================
  // 사용자 데이터 가져오기
  // ============================================
  Future<void> fetchUserData({bool loading = true}) async {
    try {
      if (loading) {
        AppRoute.pushLoading();
      }

      final device = await SecurityHandler.getDeviceInfo();
      final response = await serverManager.post('user/login', data: device);

      await _processLoginResponse(response);

    } catch (e) {
      print('사용자 데이터 가져오기 실패: $e');
      DialogManager.errorHandler('사용자 정보를 불러오는데 실패했습니다');
    } finally {
      if (loading) {
        AppRoute.popLoading();
      }
      notifyListeners();
    }
  }

  Future<void> _processLoginResponse(dynamic response) async {
    if (response.statusCode == 201) {
      _navigateToRegister();
    } else if (response.statusCode == 205) {
      await _handleDeviceConflict(response);
    } else if (response.statusCode != null && (response.statusCode! ~/ 100) == 2) {
      await _handleSuccessfulLogin(response);
    }
  }

  void _navigateToRegister() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoute.navigatorKey.currentContext != null) {
        GoRouter.of(AppRoute.navigatorKey.currentContext!).go('/register');
      }
    });
  }

  Future<void> _handleSuccessfulLogin(dynamic response) async {
    _state = UserProviderState.loggedIn;
    _user = Map.from(response.data ?? {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoute.context != null) {
        AppRoute.context!.go('/my');
      }
    });

    await _checkUserBanStatus(response);
  }

  Future<void> _checkUserBanStatus(dynamic response) async {
    if (_user?['banType'] == null) return;

    try {
      final banType = _user?['banType'];
      final startBlock = DateTime.tryParse(_user?['startBlock'] ?? '')?.toLocal();
      final endBlock = DateTime.tryParse(_user?['endBlock'] ?? '')?.toLocal();
      final lastLogin = DateTime.tryParse(response.data?['lastLogin'] ?? '')?.toLocal();

      if (lastLogin != null && startBlock != null && endBlock != null) {
        final isBanActive = lastLogin.isAfter(startBlock);

        if (isBanActive) {
          final until = DateFormat('MM월 dd일 HH시 mm분').format(endBlock);
          final banMessage = _getBanMessage(banType);

          await DialogManager.showBasicDialog(
            title: '사용자 제재 알림',
            content: '선수님께서 일정 신고 누적으로 인해 $banMessage이 ${until}까지 제한됩니다',
            confirmText: '확인',
            icon: const Icon(BootstrapIcons.ban, size: 30, color: Color(0xFF007E94)),
          );
        }
      }
    } catch (e) {
      print('사용자 제재 상태 확인 실패: $e');
    }
  }

  String _getBanMessage(String banType) {
    switch (banType) {
      case 'schedules':
        return '스케줄 생성';
      case 'community':
        return '커뮤니티 활동';
      default:
        return '일정 활동';
    }
  }

  Future<void> _handleDeviceConflict(dynamic response) async {
    final deviceName = response.data?['deviceName'] ?? '다른';

    await DialogManager.showBasicDialog(
        icon: const Icon(CupertinoIcons.device_phone_portrait, size: 30),
        title: '다른 기기에서 로그인 중',
        content: '$deviceName기기에서 로그인 중입니다.\n현재 기기로 로그인 하시겠습니까?',
        confirmText: '로그인',
        cancelText: '취소',
        onConfirm: () async {
          await _resolveDeviceConflict();
        },
        onCancel: () {
          _exitApp();
        }
    );
  }

  Future<void> _resolveDeviceConflict() async {
    try {
      final device = await SecurityHandler.getDeviceInfo();
      final response = await serverManager.put('user/deviceUpdate', data: device);

      if (response.statusCode == 200) {
        await fetchUserData();
      }
    } catch (e) {
      print('디바이스 충돌 해결 실패: $e');
      DialogManager.errorHandler('디바이스 업데이트에 실패했습니다');
    }
  }

  void _exitApp() {
    if (Platform.isIOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  // ============================================
  // 재인증
  // ============================================
  Future<bool> reCertification(String? social) async {
    try {
      switch (social) {
        case "oidc.kakao":
          await KakaoManager().kakaoLogin();
          break;
        case "google.com":
          await GoogleManager().googleLogin();
          break;
        case "apple.com":
          await AppleManager().appleLogin();
          break;
        default:
          throw Exception('지원하지 않는 소셜 로그인 타입입니다');
      }
      return true;
    } catch (e) {
      print('재인증 실패: $e');
      return false;
    }
  }

  // ============================================
  // 로그아웃 및 회원탈퇴
  // ============================================
  Future<void> logout(bool removeUser, bool reset) async {
    try {
      AppRoute.pushLoading();

      final provider = _auth.currentUser?.providerData;

      if (provider?.isEmpty ?? true) {
        await _simpleLogout();
        return;
      }

      final social = _auth.currentUser?.providerData[0].providerId;

      if (social == null) {
        throw Exception("소셜 로그인 정보를 찾을 수 없습니다");
      }

      final result = await reCertification(social);
      if (!result) {
        throw Exception("재인증에 실패했습니다");
      }

      await _unlinkSocialAccount(social);

      if (removeUser) {
        await _deleteUser();
      } else {
        await _sessionLogout();
      }

      _navigateToLogin(reset);
    } catch (error) {
      print("로그아웃 실패: $error");
      DialogManager.errorHandler('로그아웃 중 오류가 발생했습니다');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> _simpleLogout() async {
    final res = await serverManager.put('user/session/turnOff');

    if (res.statusCode == 200) {
      await _auth.signOut();
    }
    _navigateToLogin(false);
  }

  Future<void> _unlinkSocialAccount(String social) async {
    try {
      switch (social) {
        case "oidc.kakao":
          await KakaoManager().unlink();
          break;
        case "google.com":
          await GoogleManager().unLink();
          break;
      }
    } catch (e) {
      print('소셜 계정 연결 해제 실패: $e');
    }
  }

  Future<void> _deleteUser() async {
    try {
      await _auth.currentUser!.delete();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        await _auth.currentUser!.delete();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _sessionLogout() async {
    final res = await serverManager.put('user/session/turnOff');

    if (res.statusCode == 200) {
      await _auth.signOut();
    }
  }

  void _navigateToLogin(bool reset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoute.navigatorKey.currentContext != null) {
        final query = '/login?reset=$reset';
        AppRoute.navigatorKey.currentContext!.go(query);
      }
    });
  }

  // ============================================
  // 프로필 업데이트
  // ============================================
  Future<void> updateProfile() async {
    try {
      final res = await serverManager.post('user/my', data: {
        'updateAt': user?['updateAt']
      });

      if (res.statusCode == 200 && res.data != null) {
        _user = Map.from(res.data);
        notifyListeners();
      }
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      DialogManager.errorHandler('프로필 업데이트에 실패했습니다');
    }
  }

  // ============================================
  // 스케줄 관리 (개선된 메모리 효율성)
  // ============================================
  Future<void> fetchMySchedules(
      DateTime date, {
        bool force = false,
        bool reFetch = false
      }) async {
    try {
      if (reFetch) {
        _clearScheduleCache();
      }

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final from = DateTime(date.year, date.month, 1).toIso8601String();
      final to = DateTime(date.year, date.month + 1, 0, 23, 59, 59).toIso8601String();

      if (!force && _fetchedMonths.contains(monthKey)) {
        return;
      }

      final res = await serverManager.get('schedule/my?from=$from&to=$to');

      if (res.statusCode == 200 && res.data != null) {
        _processScheduleResponse(res.data, monthKey);
        _fetchedMonths.add(monthKey);
        notifyListeners();
      }

    } catch (e) {
      print('스케줄 가져오기 실패: $e');
      DialogManager.errorHandler('스케줄을 불러오는데 실패했습니다');
    }
  }

  void _processScheduleResponse(dynamic data, String monthKey) {
    if (data == null) return;

    final schedules = List<Map>.from(data);

    // 안전한 데이터 검증
    final validSchedules = schedules.where((schedule) {
      return schedule is Map &&
          schedule['scheduleId'] != null &&
          schedule['startDate'] != null;
    }).map((schedule) => Map<String, dynamic>.from(schedule)).toList();

    _schedulesCache[monthKey] = validSchedules;
  }

  void removeScheduleById(int id) {
    bool wasRemoved = false;

    for (final monthKey in _schedulesCache.keys.toList()) {
      final originalLength = _schedulesCache[monthKey]?.length ?? 0;
      _schedulesCache[monthKey]?.removeWhere((schedule) => schedule['scheduleId'] == id);

      if ((_schedulesCache[monthKey]?.length ?? 0) != originalLength) {
        wasRemoved = true;
      }
    }

    if (wasRemoved) {
      notifyListeners();
    }
  }

  Future<void> updateSchedule({required int scheduleId}) async {
    try {
      // 해당 스케줄 찾기
      Map<String, dynamic>? targetSchedule;
      String? targetMonthKey;

      for (final monthKey in _schedulesCache.keys) {
        final schedules = _schedulesCache[monthKey] ?? [];
        final index = schedules.indexWhere((s) => s['scheduleId'] == scheduleId);
        if (index != -1) {
          final schedule = schedules[index];
          if (schedule is Map) {
            targetSchedule = Map<String, dynamic>.from(schedule);
            targetMonthKey = monthKey;
            break;
          }
        }
      }

      if (targetSchedule == null || targetMonthKey == null) return;

      final response = await serverManager.get(
          'schedule/update-where-my?updateAt=${targetSchedule['updateAt']}&scheduleId=$scheduleId&participationCount=${targetSchedule['participationCount']}'
      );

      if (response.statusCode == 200 && response.data != null) {
        // 스케줄 업데이트 - 안전한 타입 변환
        final schedules = _schedulesCache[targetMonthKey] ?? [];
        final index = schedules.indexWhere((s) => s['scheduleId'] == scheduleId);
        if (index != -1) {
          final responseData = response.data;
          if (responseData is Map) {
            schedules[index] = Map<String, dynamic>.from(responseData);
            notifyListeners();
          }
        }
      } else if (response.statusCode == 202) {
        // 스케줄 삭제됨
        removeScheduleById(scheduleId);
      } else if (response.statusCode == 203 && response.data != null) {
        // 참가자 수만 변경 - 안전한 타입 변환
        final schedules = _schedulesCache[targetMonthKey] ?? [];
        final index = schedules.indexWhere((s) => s['scheduleId'] == scheduleId);
        if (index != -1) {
          final participationCount = response.data;
          if (participationCount is int || participationCount is String) {
            schedules[index]['participationCount'] = participationCount;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('스케줄 업데이트 실패: $e');
    }
  }

  // ============================================
  // 캐시 관리
  // ============================================
  void _clearScheduleCache() {
    _fetchedMonths.clear();
    _schedulesCache.clear();
  }

  void clearCache() {
    _clearScheduleCache();
    notifyListeners();
  }

  void clearUserData() {
    _user = null;
    _clearScheduleCache();
    _state = UserProviderState.none;
    notifyListeners();
  }
}