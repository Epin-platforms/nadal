import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Reorder_List.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Team_Reorder_List.dart';
import '../../../../manager/project/Import_Manager.dart';
import 'kdk/Nadal_KDK_Reorder_List.dart';

class GameState2 extends StatelessWidget {
  const GameState2({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  Widget build(BuildContext context) {
    // 안전성을 위한 null 체크
    if (scheduleProvider.schedule == null) {
      return const Center(
        child: Text('게임 정보를 불러올 수 없습니다.'),
      );
    }

    final gameType = scheduleProvider.gameType;
    if (gameType == null) {
      return const Center(
        child: Text('올바르지 않은 게임 타입입니다.'),
      );
    }

    // 게임 타입에 따른 위젯 반환
    switch (gameType) {
      case GameType.kdkSingle:
      case GameType.kdkDouble:
        return NadalKDKReorderList(
          scheduleProvider: scheduleProvider,
        );

      case GameType.tourSingle:
        return TournamentReorderList(
          scheduleProvider: scheduleProvider,
        );

      case GameType.tourDouble:
        return TournamentTeamReorderList(
          scheduleProvider: scheduleProvider,
        );
    }
  }
}