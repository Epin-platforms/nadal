import 'package:my_sports_calendar/provider/game/Game_Provider.dart';
import 'package:my_sports_calendar/screen/schedule/game/state4/widget/Kdk_Result.dart';
import 'package:my_sports_calendar/screen/schedule/game/state4/widget/My_Level.dart';
import 'package:my_sports_calendar/screen/schedule/game/state4/widget/My_Result.dart';

import '../../../../manager/project/Import_Manager.dart';

//게임중
class GameState4 extends StatefulWidget {
  const GameState4({super.key, required this.gameProvider});
  final GameProvider gameProvider;

  @override
  State<GameState4> createState() => _GameState4State();
}

class _GameState4State extends State<GameState4> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.gameProvider.result == null){
        widget.gameProvider.fetchResult();
      }
      if(widget.gameProvider.tables == null){
        widget.gameProvider.fetchTables();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.gameProvider.result == null || widget.gameProvider.tables == null){
      return Center(child: NadalCircular());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if(widget.gameProvider.scheduleProvider.scheduleMembers!.containsKey(FirebaseAuth.instance.currentUser!.uid))//내가 참가했다면
            MyResult(gameProvider: widget.gameProvider),
          if(widget.gameProvider.scheduleProvider.scheduleMembers!.containsKey(FirebaseAuth.instance.currentUser!.uid))//내가 참가했다면
            MyLevel(gameProvider: widget.gameProvider),
          //대진표 결과
          if(widget.gameProvider.scheduleProvider.schedule!['isKDK'] == 1)
          KdkResult(gameProvider: widget.gameProvider)
        ],
      ),
    );
  }
}
