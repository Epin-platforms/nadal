// 개선된 카카오 공유 사용 예시

import '../../manager/project/Import_Manager.dart';
import '../../model/share/Share_Parameter.dart';
import '../../widget/Share_Bottom_Sheet.dart';

// 다른 사용 예시들

// 0. 프로필 공유
void shareApp(BuildContext context, String uid) {
  final shareParameter = ShareParameter(
    title: "함께 나달에서 경기해요!",
    subTitle: '나달에서 일정을 만들고 친구와 함게해보세요',
    routing: '/user/$uid',
  );

  if (shareParameter.isValid) {
    _executeShare(context, shareParameter);
  }
}

/*void shareEvent(BuildContext context, Map<String, dynamic> eventData) {
  final shareParameter = ShareParameter(
    title: eventData['eventName']?.toString() ?? '이벤트',
    subTitle: '흥미로운 이벤트에 참여해보세요!',
    link: eventData['eventUrl']?.toString(),
    imageUrl: eventData['eventImage']?.toString(),
    routing: '/event/${eventData['eventId']}',
  );

  if (shareParameter.isValid) {
    _executeShare(context, shareParameter);
  }
}*/

// 2. 리그 공유
/*void shareLeague(BuildContext context, String leagueId, String leagueName) {
  final shareParameter = ShareParameter(
    title: leagueName,
    subTitle: '같이 리그에 참여해볼까요?',
    routing: '/league',
  );

  _executeShare(context, shareParameter);
}*/

// 3. 커뮤니티 공유
void shareRoom(BuildContext context, int roomId, String roomName, String? imageUrl) {
  final shareParameter = ShareParameter(
    title: roomName,
    imageUrl: imageUrl,
    subTitle: '우리 커뮤니티에 함께해요!',
    routing: '/room/$roomId',
  );

  _executeShare(context, shareParameter);
}

void shareSchedule(BuildContext context, int scheduleId, String title){
  // ShareParameter 생성 (검증 포함)
  final shareParameter = ShareParameter(
    title: title,
    subTitle: '지금 일정에 참여해볼까요?',
    routing: '/schedule/$scheduleId', // 정규화됨
  );

  _executeShare(context, shareParameter);
}

// 공통 공유 실행 함수
void _executeShare(BuildContext context, ShareParameter shareParameter) {
  try {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8.h,
      ),
      builder: (context) => ShareBottomSheet(
        shareParameter: shareParameter,
      ),
    );
  } catch (e) {
    print('공유 실행 오류: $e');
  }
}

// 딥링크 테스트용 함수
void _testDeepLink(BuildContext context, String testRouting) {
  final testParameter = ShareParameter(
    title: '딥링크 테스트',
    subTitle: '딥링크가 정상 작동하는지 테스트합니다',
    routing: testRouting,
  );

  print('테스트 딥링크 생성: ${testParameter.toString()}');
  print('정규화된 라우팅: ${testParameter.normalizedRouting}');

  _executeShare(context, testParameter);
}