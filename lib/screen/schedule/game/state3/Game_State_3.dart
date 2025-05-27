import 'package:my_sports_calendar/screen/schedule/game/state3/kdk/KDK_Double_View.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/kdk/KDK_Single_VIew.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Tournament_Double_View.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Tournament_Single_View.dart';

import '../../../../manager/project/Import_Manager.dart';

//게임진행중
class GameState3 extends StatefulWidget {
  const GameState3({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  State<GameState3> createState() => _GameState3State();
}


class _GameState3State extends State<GameState3> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.scheduleProvider.gameTables == null){
        widget.scheduleProvider.fetchGameTables();
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    if(widget.scheduleProvider.gameTables == null){
      return Center(
        child: NadalCircular(),
      );
    }
    final isKDK = widget.scheduleProvider.schedule?['isKDK'] == 1;
    final isSinge =  widget.scheduleProvider.schedule?['isSingle'] == 1;
    if(isKDK){
      return isSinge ? KdkSingleView(scheduleProvider: widget.scheduleProvider,) : KdkDoubleView(scheduleProvider: widget.scheduleProvider);
    }else{ //토너먼트
      return  isSinge ? TournamentSingleView(scheduleProvider: widget.scheduleProvider) : TournamentTeamView(scheduleProvider: widget.scheduleProvider);
    }
  }
}
