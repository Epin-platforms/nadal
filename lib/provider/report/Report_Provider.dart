// 신고 관리자 클래스
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/report/Report_Model.dart';

import '../../manager/project/Import_Manager.dart';

// 신고 사유 모델
class ReportReason {
  final String id;
  final String title;
  final String description;
  final Set<TargetType> applicableTargets;

  const ReportReason({
    required this.id,
    required this.title,
    required this.description,
    required this.applicableTargets,
  });
}


class ReportProvider extends ChangeNotifier {
  static const List<ReportReason> _allReasons = [
    // 공통 사유
    ReportReason(
      id: 'spam',
      title: '스팸/광고',
      description: '불필요한 광고나 스팸성 콘텐츠',
      applicableTargets: {
        TargetType.chat,
        TargetType.schedule,
        TargetType.room,
        TargetType.user
      },
    ),
    ReportReason(
      id: 'inappropriate_content',
      title: '부적절한 콘텐츠',
      description: '욕설, 폭력적이거나 불쾌한 내용',
      applicableTargets: {
        TargetType.chat,
        TargetType.schedule,
        TargetType.room,
        TargetType.user
      },
    ),
    ReportReason(
      id: 'harassment',
      title: '괴롭힘/따돌림',
      description: '다른 사용자를 괴롭히거나 따돌리는 행위',
      applicableTargets: {
        TargetType.chat,
        TargetType.user
      },
    ),
    ReportReason(
      id: 'false_information',
      title: '허위 정보',
      description: '거짓되거나 잘못된 정보 유포',
      applicableTargets: {
        TargetType.chat,
        TargetType.schedule,
        TargetType.room
      },
    ),
    ReportReason(
      id: 'fraud',
      title: '사기/금전적 피해',
      description: '돈을 요구하거나 금전적 피해를 주는 사기 행위',
      applicableTargets: {
        TargetType.chat,
        TargetType.schedule,
        TargetType.room,
        TargetType.user
      },
    ),

    // 채팅 전용
    ReportReason(
      id: 'personal_info_leak',
      title: '개인정보 유출',
      description: '타인의 개인정보를 무단으로 공유',
      applicableTargets: {TargetType.chat},
    ),

    // 스케줄 전용
    ReportReason(
      id: 'fake_schedule',
      title: '가짜 일정',
      description: '실제로 존재하지 않는 허위 일정',
      applicableTargets: {TargetType.schedule},
    ),
    ReportReason(
      id: 'inappropriate_schedule',
      title: '부적절한 일정',
      description: '불법적이거나 위험한 활동 일정',
      applicableTargets: {TargetType.schedule},
    ),

    // 방 전용
    ReportReason(
      id: 'misleading_room_info',
      title: '방 정보 허위기재',
      description: '방 제목이나 설명이 실제 내용과 다름',
      applicableTargets: {TargetType.room},
    ),
    ReportReason(
      id: 'inappropriate_room_name',
      title: '부적절한 방 이름',
      description: '욕설이나 불쾌한 내용이 포함된 방 이름',
      applicableTargets: {TargetType.room},
    ),

    // 사용자 전용
    ReportReason(
      id: 'fake_profile',
      title: '가짜 프로필',
      description: '타인을 사칭하거나 허위 정보로 만든 프로필',
      applicableTargets: {TargetType.user},
    ),
    ReportReason(
      id: 'inappropriate_profile',
      title: '부적절한 프로필',
      description: '선정적이거나 불쾌한 프로필 이미지/정보',
      applicableTargets: {TargetType.user},
    ),

    // 기타
    ReportReason(
      id: 'other',
      title: '기타',
      description: '위에 해당하지 않는 다른 문제',
      applicableTargets: {
        TargetType.chat,
        TargetType.schedule,
        TargetType.room,
        TargetType.user
      },
    ),
  ];



  String? _selectedReasonId;
  String _additionalComment = '';
  bool _isSubmitting = false;

  String? get selectedReasonId => _selectedReasonId;
  String get additionalComment => _additionalComment;
  bool get isSubmitting => _isSubmitting;

  List<ReportReason> getApplicableReasons(TargetType targetType) {
    return _allReasons
        .where((reason) => reason.applicableTargets.contains(targetType))
        .toList();
  }

  void selectReason(String? reasonId) {
    _selectedReasonId = reasonId;
    notifyListeners();
  }

  void updateAdditionalComment(String comment) {
    _additionalComment = comment;
    notifyListeners();
  }

  Future<bool> submitReport({
    required TargetType targetType,
    required String targetId,
  }) async {
    if (_selectedReasonId == null) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      // TODO: 실제 API 호출
      // 신고 데이터 구성
      final ReportModel report = ReportModel(
          description: _additionalComment,
          reason: _selectedReasonId!,
          target_id: targetId,
          target_type: targetType
      );

      final res = await serverManager.post('app/report', data: report.toMap());

      if(res.statusCode == 200){
        // 성공 시 초기화
        _selectedReasonId = null;
        _additionalComment = '';
        return true;
      }

      return false;
    } catch (e) {
      print('신고 제출 실패: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}