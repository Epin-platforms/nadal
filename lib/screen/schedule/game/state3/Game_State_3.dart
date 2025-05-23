import 'package:my_sports_calendar/screen/schedule/game/state3/kdk/KDK_Double_View.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/kdk/KDK_Single_VIew.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Tournament_Double_View.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Tournament_Single_View.dart';

import '../../../../manager/project/Import_Manager.dart';
import '../../../../provider/game/Game_Provider.dart';

//게임진행중
class GameState3 extends StatefulWidget {
  const GameState3({super.key, required this.gameProvider, required this.scheduleProvider});
  final GameProvider gameProvider;
  final ScheduleProvider scheduleProvider;
  @override
  State<GameState3> createState() => _GameState3State();
}


class _GameState3State extends State<GameState3> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.gameProvider.tables == null){
        widget.gameProvider.fetchTables();
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    if(widget.gameProvider.tables == null){
      return Center(
        child: NadalCircular(),
      );
    }
    final isKDK = widget.scheduleProvider.schedule?['isKDK'] == 1;
    final isSinge =  widget.scheduleProvider.schedule?['isSingle'] == 1;
    if(isKDK){
      return isSinge ? KdkSingleView(gameProvider: widget.gameProvider, scheduleProvider: widget.scheduleProvider,) : KdkDoubleView(gameProvider: widget.gameProvider, scheduleProvider: widget.scheduleProvider);
    }else{ //토너먼트
      return  isSinge ? TournamentSingleView(gameProvider: widget.gameProvider, scheduleProvider: widget.scheduleProvider) : TournamentTeamView(gameProvider: widget.gameProvider, scheduleProvider: widget.scheduleProvider);
    }
  }
}
