

import '../../../../../manager/project/Import_Manager.dart';

class KdkResult extends StatefulWidget {
  const KdkResult({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  State<KdkResult> createState() => _KdkResultState();
}

class _KdkResultState extends State<KdkResult> {
  List members = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      members = widget.scheduleProvider.scheduleMembers!.entries.toList();
      members.sort((a,b) => a.value['ranking'].compareTo(b.value['ranking']));
      setState(() {
      });
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if(members.isEmpty){
      return const SizedBox(
        height: 300,
        child: NadalCircular(size: 30,),
      );
    }

    return Column(
      children: [
        Text('대진표 결과', style: theme.textTheme.titleMedium,),
        SizedBox(height: 24.h,),
        //상단부
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                  width: 30.w,
                  alignment: Alignment.center,
                  child: Text('순위', style: theme.textTheme.labelMedium)),
              Container(
                  width: 80.w,
                  alignment: Alignment.center,
                  child: Text('닉네임', style: theme.textTheme.labelMedium,)),
              Expanded(
                  child: Row(
                    children: List.generate(widget.scheduleProvider.scheduleMembers!.entries.length == 4 ? 3 : 4, (index) => Flexible(child: Center(child: Text('게임${index+1}', style: theme.textTheme.labelMedium))),),
                  ))
            ],
          ),
        ),

        ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index){
              final member = members.map((e)=> e.value).toList()[index];
              final attendGame =  widget.scheduleProvider.schedule!['isSingle'] == 1 ? //단식이라면
              widget.scheduleProvider.gameTables!.entries.where((element) => element.value['player1_0'] == member['uid'] || element.value['player2_0'] == member['uid']).toList() :
                  //복식일경우
              widget.scheduleProvider.gameTables!.entries.where((element) =>
              element.value['player1_0'] == member['uid'] || element.value['player1_1'] == member['uid'] || element.value['player2_0'] == member['uid'] || element.value['player2_1'] == member['uid']
              ).toList();

              final List<String> score = attendGame.map((e){
                if(widget.scheduleProvider.schedule!['isSingle'] == 1){
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
                height: 40.h,
                child: Center(
                  child:
                  Row(
                    children: [
                      Container(
                          width: 30.w,
                          alignment: Alignment.center,
                          child: Text('${member['ranking']}', style: theme.textTheme.labelMedium)),
                      Container(
                          width: 80.w,
                          alignment: Alignment.center,
                          child: Text(TextFormManager.profileText(member['nickName'], member['name'], member['birthYear'], member['gender'], useNickname: member['gender'] == null), style: theme.textTheme.labelMedium,overflow: TextOverflow.ellipsis,)),
                      Expanded(
                          child: Row(
                            children: List.generate(widget.scheduleProvider.scheduleMembers!.entries.length == 4 ? 3 : 4,
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
