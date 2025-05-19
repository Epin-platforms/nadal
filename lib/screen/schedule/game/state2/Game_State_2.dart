import 'package:my_sports_calendar/provider/game/Game_Provider.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Reorder_List.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Team_Reorder_List.dart';

import '../../../../manager/project/Import_Manager.dart';
import 'kdk/Nadal_KDK_Reorder_List.dart';

class GameState2 extends StatelessWidget {
  const GameState2({super.key, required this.gameProvider});
  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    final isKDK = gameProvider.scheduleProvider.schedule?['isKDK'] == 1;
    final isSingle = gameProvider.scheduleProvider.schedule?['isSingle'] == 1;

    if(isKDK){ //KDK인경우
      return NadalKDKReorderList(gameProvider: gameProvider);
    }else{ //토너먼트인경우
      if(isSingle){
        return TournamentReorderList(gameProvider: gameProvider,);
      }else{
        return TournamentTeamReorderList(gameProvider: gameProvider);
      }
    }
  }
}
