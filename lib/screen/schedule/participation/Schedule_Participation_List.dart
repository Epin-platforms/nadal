import 'package:my_sports_calendar/screen/schedule/participation/Participation_Team.dart';
import 'package:my_sports_calendar/screen/schedule/participation/Prticipation_Solo.dart';

import '../../../manager/project/Import_Manager.dart';

class ScheduleParticipationList extends StatefulWidget {
  const ScheduleParticipationList({super.key});

  @override
  State<ScheduleParticipationList> createState() => _ScheduleParticipationListState();
}

class _ScheduleParticipationListState extends State<ScheduleParticipationList> {
  late ScheduleProvider provider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_)=> provider.updateMembers);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<ScheduleProvider>(context);
    print('${provider.schedule?['isKDK']}');

    if(provider.schedule?['isKDK'] == 0 && provider.schedule?['isSingle'] == 0){

      return ParticipationTeam(provider: provider);
    }

    return ParticipationSolo(provider: provider);
  }
}
