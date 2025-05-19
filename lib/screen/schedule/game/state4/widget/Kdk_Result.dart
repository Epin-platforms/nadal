import 'package:my_sports_calendar/provider/game/Game_Provider.dart';

import '../../../../../manager/project/Import_Manager.dart';

class KdkResult extends StatelessWidget {
  const KdkResult({super.key, required this.gameProvider});
  final GameProvider gameProvider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('대진표 결과', style: theme.textTheme.titleMedium,),
        SizedBox(height: 24,),
        //상단부
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text('순위', style: theme.textTheme.labelMedium)),
              Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text('닉네임', style: theme.textTheme.labelMedium,)),
              Expanded(
                  child: Row(
                    children: List.generate(gameProvider.scheduleProvider.scheduleMembers!.entries.length == 4 ? 3 : 4, (index) => Flexible(child: Center(child: Text('게임${index+1}', style: theme.textTheme.labelMedium))),),
                  ))
            ],
          ),
        ),

        ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: gameProvider.scheduleProvider.scheduleMembers!.entries.length,
            itemBuilder: (context, index){
              final member = gameProvider.scheduleProvider.scheduleMembers!.entries.map((e)=> e.value).toList()[index];
              final attendGame =  gameProvider.scheduleProvider.schedule!['isSingle'] == 1 ? //단식이라면
              gameProvider.tables!.entries.where((element) => element.value['player1_0'] == member['uid'] || element.value['player2_0'] == member['uid']).toList() :
                  //복식일경우
              gameProvider.tables!.entries.where((element) =>
              element.value['player1_0'] == member['uid'] || element.value['player1_1'] == member['uid'] || element.value['player2_0'] == member['uid'] || element.value['player2_1'] == member['uid']
              ).toList();

              final List<String> score = attendGame.map((e){
                if(gameProvider.scheduleProvider.schedule!['isSingle'] == 1){
                  if(e.value['player1_0'] == member['uid']){
                    return '${e.value['score1']} : ${e.value['score2']}';
                  }else{
                    return '${e.value['score2']} : ${e.value['score1']}';
                  }
                }else{
                  if(e.value['player1_0'] == member['uid'] || e.value['player1_1'] == member['uid']){
                    return '${e.value['score1']} : ${e.value['score2']}';
                  }else{
                    return '${e.value['score2']} : ${e.value['score1']}';
                  }
                }
              }).toList();

              return SizedBox(
                height: 40,
                child: Center(
                  child:
                  Row(
                    children: [
                      Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text('${index+1}', style: theme.textTheme.labelMedium)),
                      Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(TextFormManager.profileText(member['nickName'], member['name'], member['birthYear'], member['gender'], useNickname: member['gender'] == null), style: theme.textTheme.labelMedium,overflow: TextOverflow.ellipsis,)),
                      Expanded(
                          child: Row(
                            children: List.generate(gameProvider.scheduleProvider.scheduleMembers!.entries.length == 4 ? 3 : 4,
                                  (index) => Flexible(child: Center(child: Text(score[index], style: theme.textTheme.labelMedium))),),
                          ))
                    ],
                  ),
                ),
              );
            })
      ],
    );
  }
}
