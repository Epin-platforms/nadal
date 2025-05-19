import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/widget/Nadal_Score_Input.dart';

class GameManager{
  static final min_kdk_single_member = 4;
  static final max_kdk_single_member = 20;
  static final min_kdk_double_member = 5;
  static final max_kdk_double_member = 30;

  static final min_tour_single_member = 4;
  static final max_tour_single_member = 100;

  static final min_tour_double_member = 2;
  static final max_tour_double_member = 50;

  //멤버를 팀 네임으로 만들어주는 함수
  static Map<String, List<String?>> groupTeams(Map data) {
    final Map<String, List<String?>> grouped = {};

    data.forEach((uid, userInfo) {
      final teamName = userInfo['teamName'];
      if (teamName == null || teamName.toString().isEmpty) return;

      grouped.putIfAbsent(teamName, () => []);
      grouped[teamName]!.add(uid);
    });

    // 항상 2명 맞추기
    grouped.updateAll((team, members) {
      if (members.length < 2) {
        members.add(null); // 부족하면 null 채우기
      }
      return members;
    });

    return grouped;
  }

  static Future<int?> scoreInput(int finalScore, int currentScore) async{
    final context = AppRoute.context!;

    final res = await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context, builder: (_){
      return NadalScoreInput(currentScore: currentScore, finalScore: finalScore);
    });

    return res;
  }

}