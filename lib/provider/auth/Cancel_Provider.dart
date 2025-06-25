import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 탈퇴 사유 데이터 모델
class WithdrawalReason {
  final String id;
  final String text;
  bool isSelected;

  WithdrawalReason({
    required this.id,
    required this.text,
    this.isSelected = false,
  });
}


class CancelProvider extends ChangeNotifier{
// 탈퇴 사유 리스트
  List<WithdrawalReason> reasons = [
    WithdrawalReason(id: '1', text: '서비스 이용이 불편해요'),
    WithdrawalReason(id: '2', text: '원하는 기능이 없어요'),
    WithdrawalReason(id: '3', text: '비슷한 다른 서비스를 이용할 예정이에요'),
    WithdrawalReason(id: '4', text: '개인정보 보호에 대한 우려가 있어요'),
    WithdrawalReason(id: '5', text: '오류가 너무 많아요'),
    WithdrawalReason(id: '6', text: '자주 사용하지 않아요'),
    WithdrawalReason(id: '7', text: '기타'),
  ];

  String otherReason = ''; // 기타 사유 텍스트
  bool isAgreed = false; // 동의 여부
  String _errorMessage = ''; // 오류 메시지

  // Getter 메서드들
  String get errorMessage => _errorMessage;

  // 탈퇴 버튼 활성화 여부 계산
  bool get canWithdraw {
    bool hasSelectedReason = reasons.any((reason) => reason.isSelected);
    bool isOtherReasonValid = reasons.last.isSelected ? otherReason.trim().isNotEmpty : true;
    return hasSelectedReason && isOtherReasonValid && isAgreed;
  }

  // 사유 선택 토글 메서드
  void toggleReason(String id) {
    for (var reason in reasons) {
      if (reason.id == id) {
        reason.isSelected = !reason.isSelected;
      }
    }
    notifyListeners();
  }

  // 기타 사유 업데이트 메서드
  void updateOtherReason(String text) {
    otherReason = text;
    notifyListeners();
  }

  // 동의 체크박스 토글 메서드
  void toggleAgreement() {
    isAgreed = !isAgreed;
    notifyListeners();
  }

  // 폼 리셋 메서드
  void resetForm() {
    for (var reason in reasons) {
      reason.isSelected = false;
    }
    otherReason = '';
    isAgreed = false;
    _errorMessage = '';
    notifyListeners();
  }

  // 선택된 사유들을 API 요청 형식으로 변환
  Map<String, dynamic> _getReasonPayload() {
    // 선택된 사유 ID 리스트
    List<String> selectedReasonIds = reasons
        .where((reason) => reason.isSelected)
        .map((reason) => reason.id)
        .toList();

    // API 요청 데이터 형식

    Map<String, dynamic> payload = {
      'reasonId': selectedReasonIds.toString(),
    };

    // 기타 사유가 선택된 경우 추가
    if (reasons.last.isSelected && otherReason.trim().isNotEmpty) {
      payload['otherReason'] = otherReason.trim();
    }

    return payload;
  }

  // 탈퇴 전 사용자의 활성 예약/주문 확인
  Future<bool> _checkActiveRoomsAndSchedule() async {
    try {
      //운영중인 방 혹은 진행중인 게임이있는지
      final response = await serverManager.get('user/cancel/check');

      if (response.statusCode == 200) {
        final data = response.data;

        // data가 Map 타입인지 확인
        if (data is Map) {
          // roomId 확인
          if (data.containsKey('roomId') && data['roomId'] != null) {
            _errorMessage = '운영중인 방이 존재해요!\n확인 후 다시 시도해주세요';
            return false;
          }

          // scheduleId 확인
          if (data.containsKey('scheduleId') && data['scheduleId'] != null) {
            _errorMessage = '진행중인 일정이 존재해요!\n확인 후 다시 시도해주세요';
            return false;
          }
        }
        return true;
      } else {
        _errorMessage = '사용자 정보를 확인하는 중 오류가 발생했습니다.';
        return false;
      }
    } catch (e) {
      print(e);
      _errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      return false;
    }
  }

  // 실제 회원탈퇴 처리를 수행하는 메서드
  Future<bool> withdrawMembership() async {
    // 상태 업데이트: 로딩 중
    AppRoute.pushLoading();
    final _auth = FirebaseAuth.instance;
    try {
      // 예민한 작업을 위해 로그인부터 재진행
      SnackBarManager.showCleanSnackBar(AppRoute.context!, '3초 후\n회원탈퇴를 위해 사용자 재인증을 시도 합니다');

      await Future.delayed(const Duration(seconds: 3));
      try{
        await AppRoute.context!.read<UserProvider>().reCertification(_auth.currentUser!.providerData[0].providerId);
      }catch(error){
        print(error);
        _errorMessage = '사용자 인증에 실패했습니다';
        _errorHandler();
        return false;
      }

      bool canProceed = await _checkActiveRoomsAndSchedule();

      if (canProceed == false) {
        _errorHandler();
        return false;
      }

      // 탈퇴 사유 데이터 준비
      final payload = _getReasonPayload();

      // API 호출: 회원탈퇴 요청
      final response = await serverManager.post('user/cancel', data: payload);

      // 성공 처리
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 로컬 데이터 삭제 (토큰, 사용자 정보 등)
        await _clearLocalUserData();
        //현재 계정 삭제
        _auth.currentUser!.delete();
        return true;
      } else {
        // 오류 처리
        _errorMessage = response.data['message'] ?? '탈퇴 처리 중 오류가 발생했습니다.';
        _errorHandler();
        return false;
      }
    } catch (e) {
      _errorMessage = '탈퇴 처리 중 오류가 발생했습니다.';
      _errorHandler();
      return false;
    }
  }

  // 로컬 사용자 데이터 삭제
  Future<void> _clearLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('🗑️ 회원탈퇴 - 로컬 데이터 삭제 시작');

      // ============================================
      // 1. 🎨 테마 설정
      // ============================================
      await prefs.remove('epin.nadal.theme_mode');
      print('✅ 테마 설정 삭제 완료');

      // ============================================
      // 2. 🔍 검색 기록
      // ============================================
      await prefs.remove('epin.nadal.rooms_search_key.open');
      await prefs.remove('epin.nadal.rooms_search_key.club');
      print('✅ 검색 기록 삭제 완료');

      // ============================================
      // 3. 🔐 권한 관리 관련 (모든 권한 데이터)
      // ============================================

      // 권한 프로세스 관련
      await prefs.remove('epin_nadal_has_requested_permissions');
      await prefs.remove('epin_nadal_permission_requested_date');
      await prefs.remove('epin_nadal_permission_process_completed');

      // 개별 권한별 데이터 삭제 (동적으로 처리)
      final allKeys = prefs.getKeys();

      // 권한 결과 키들 삭제
      final permissionResultKeys = allKeys.where((key) =>
          key.startsWith('epin_nadal_permission_result_')).toList();
      for (final key in permissionResultKeys) {
        await prefs.remove(key);
      }

      // 권한 재시도 키들 삭제
      final canRetryKeys = allKeys.where((key) =>
          key.startsWith('epin_nadal_can_retry_')).toList();
      for (final key in canRetryKeys) {
        await prefs.remove(key);
      }

      // 권한 스킵 키들 삭제
      final permissionSkippedKeys = allKeys.where((key) =>
          key.startsWith('epin_nadal_permission_skipped_')).toList();
      for (final key in permissionSkippedKeys) {
        await prefs.remove(key);
      }

      print('✅ 권한 관리 데이터 삭제 완료');

      // ============================================
      // 4. 📱 광고 ATT 권한 관련
      // ============================================
      await prefs.remove('advertisement_att_requested');
      await prefs.remove('advertisement_att_granted');
      print('✅ 광고 ATT 권한 데이터 삭제 완료');

      // ============================================
      // 5. 🍎 Apple 로그인 관련
      // ============================================
      await prefs.remove('apple_provided_email');
      print('✅ Apple 로그인 데이터 삭제 완료');

      // ============================================
      // 6. 🔄 기타 사용자별 캐시/설정 (필요 시 추가)
      // ============================================

      // 향후 추가될 수 있는 사용자별 설정들을 위한 패턴 매칭
      // 예: 'user_settings_', 'cache_', 'preference_' 등의 접두사를 가진 키들

      final userSpecificKeys = allKeys.where((key) =>
      key.startsWith('user_') ||
          key.startsWith('cache_') ||
          key.startsWith('preference_') ||
          key.contains('_user_') ||
          key.contains('_profile_')
      ).toList();

      for (final key in userSpecificKeys) {
        await prefs.remove(key);
        print('🗑️ 사용자별 키 삭제: $key');
      }

      print('✅ 모든 로컬 사용자 데이터 삭제 완료');

      AppBadgePlus.updateBadge(0);
    } catch (e) {
      // 로컬 데이터 삭제 실패 시에도 탈퇴 프로세스는 계속 진행
      debugPrint('❌ 로컬 데이터 삭제 중 오류: $e');
    }
  }

  void _errorHandler(){
    AppRoute.popLoading();
    DialogManager.showBasicDialog(title: '탈퇴에 실패했어요!', content: _errorMessage, confirmText: '확인');
  }
}