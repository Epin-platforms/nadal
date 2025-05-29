import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/main.dart';
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
    notifyListeners();

    // 안전한 네비게이션
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
      // 신규 사용자 - 가입 페이지로 이동
      _navigateToRegister();
    }else if (response.statusCode == 205) {
      // 디바이스 충돌 - 다른 기기에서 로그인 중
      await _handleDeviceConflict(response);
    }else if (response.statusCode != null && (response.statusCode! ~/ 100) == 2) {
      // 기존 사용자 - 로그인 성공
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
    _user = response.data;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoute.context != null) {
        AppRoute.context!.go('/my');
      }
    });

    // 사용자 제재 상태 확인
    await _checkUserBanStatus(response);
  }

  Future<void> _checkUserBanStatus(dynamic response) async {
    if (_user?['banType'] == null) return;

    try {
      final banType = _user?['banType'];
      final startBlock = DateTime.tryParse(_user?['startBlock'])?.toLocal();
      final endBlock = DateTime.tryParse(_user?['endBlock'])?.toLocal(); // 수정: 'startBlock' -> 'endBlock'
      final lastLogin = DateTime.tryParse(response.data['lastLogin'])?.toLocal();

      if (lastLogin != null && startBlock != null && endBlock != null) {
        final isBanActive = lastLogin.isAfter(startBlock);

        if (isBanActive) {
          final until = DateFormat('MM월 dd일 HH시 mm분').format(endBlock); // 수정: 'hh' -> 'HH'
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

      // Provider 정보가 없는 경우 처리
      if (provider?.isEmpty ?? true) {
        await _simpleLogout();
        return;
      }

      final social = _auth.currentUser?.providerData[0].providerId;

      if (social == null) {
        throw Exception("소셜 로그인 정보를 찾을 수 없습니다");
      }

      // 재인증 진행
      final result = await reCertification(social);
      if (!result) {
        throw Exception("재인증에 실패했습니다");
      }

      // 소셜 링크 해제
      await _unlinkSocialAccount(social);

      // 사용자 삭제 또는 로그아웃 처리
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
      // Apple은 unlink 기능이 없으므로 생략
      }
    } catch (e) {
      print('소셜 계정 연결 해제 실패: $e');
      // 에러가 발생해도 로그아웃은 계속 진행
    }
  }

  Future<void> _deleteUser() async {
    try {
      await _auth.currentUser!.delete();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // 재인증 후 다시 시도
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
        'updateAt': user!['updateAt']
      });

      if (res.statusCode == 200) {
        _user = Map.of(res.data);
        notifyListeners();
      }
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      DialogManager.errorHandler('프로필 업데이트에 실패했습니다');
    }
  }

  // ============================================
  // 사용자 스케줄 관리
  // ============================================
  List<Map> _schedules = [];
  List<Map> get schedules => _schedules;

  List<String> _fetchCached = [];
  List<String> get fetchCached => _fetchCached;

  Future<void> fetchMySchedules(
      DateTime date, {
        bool force = false,
        bool reFetch = false
      }) async {
    try {
      if (reFetch) {
        _fetchCached.clear();
        _schedules.clear();
      }

      final from = DateTime(date.year, date.month, 1).toIso8601String();
      final to = DateTime(date.year, date.month + 1, 0, 23, 59, 59).toIso8601String();

      // 이미 캐시된 데이터가 있고 강제 새로고침이 아닌 경우 스킵
      if (!force && fetchCached.contains(from)) {
        return;
      }

      final res = await serverManager.get('schedule/my?from=$from&to=$to');

      if (res.statusCode == 200) {
        _processScheduleResponse(res.data);
        _fetchCached.add(from);
      }

    } catch (e) {
      print('스케줄 가져오기 실패: $e');
      DialogManager.errorHandler('스케줄을 불러오는데 실패했습니다');
    }
  }

  void _processScheduleResponse(dynamic data) {
    final newSchedules = List<Map>.from(data);
    final existingIds = _schedules.map((e) => e['scheduleId']).toSet();
    final filtered = newSchedules
        .where((schedule) => !existingIds.contains(schedule['scheduleId']))
        .toList();

    _schedules.addAll(filtered);
    notifyListeners();
  }

  void removeScheduleById(int id) {
    final removedCount = _schedules.length;
    _schedules.removeWhere((schedule) => schedule['scheduleId'] == id);

    // 실제로 제거된 경우에만 notifyListeners 호출
    if (_schedules.length != removedCount) {
      notifyListeners();
    }
  }

  // ============================================
  // 캐시 관리
  // ============================================
  void clearCache() {
    _fetchCached.clear();
    _schedules.clear();
    notifyListeners();
  }

  void clearUserData() {
    _user = null;
    _schedules.clear();
    _fetchCached.clear();
    _state = UserProviderState.none;
    notifyListeners();
  }
}