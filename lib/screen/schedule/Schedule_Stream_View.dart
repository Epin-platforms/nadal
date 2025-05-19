import 'package:my_sports_calendar/screen/schedule/Schedule.dart';

import '../../manager/project/Import_Manager.dart';
import '../../provider/game/Game_Provider.dart';

class ScheduleStreamView extends StatelessWidget {
  const ScheduleStreamView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    // 조건 만족 시 GameProvider 초기화 시도
    final schedule = scheduleProvider.schedule;

    if (schedule == null) {
      return Material(child: const Center(child: CircularProgressIndicator()));
    }

    final gameProvider = context.read<GameProvider>();

    if(schedule['tag'] == "게임"){
      gameProvider.initGameProvider(scheduleProvider);
    }

     return Schedule();
   }
}

