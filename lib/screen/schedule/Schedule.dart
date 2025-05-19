import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/screen/schedule/Schedule_Main.dart';
import 'package:my_sports_calendar/screen/schedule/game/state1/Game_State_1.dart';
import 'package:my_sports_calendar/screen/schedule/widget/Schedule_Step_Selector.dart';
import '../../manager/project/Import_Manager.dart';
import '../../provider/game/Game_Provider.dart';
import 'game/block/Game_Block.dart';
import 'game/state2/Game_State_2.dart';
import 'game/state3/Game_State_3.dart';
import 'game/state4/Game_State_4.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late ScheduleProvider scheduleProvider;
  late UserProvider userProvider;
  late CommentProvider commentProvider;
  late GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    scheduleProvider = Provider.of<ScheduleProvider>(context);
    userProvider = Provider.of<UserProvider>(context);
    commentProvider = Provider.of<CommentProvider>(context);
    gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    if(scheduleProvider.schedule == null){
      return Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '스케줄',
          actions: [
            NadalIconButton(
                onTap: (){
                  if(scheduleProvider.schedule!['uid'] == FirebaseAuth.instance.currentUser!.uid){
                    showCupertinoModalPopup(context: context, builder: (context){
                      final nav = Navigator.of(context);
                      return NadalSheet(
                          actions: [
                            CupertinoActionSheetAction(
                                onPressed: (){
                                  nav.pop();
                                },
                                child: Text('공유', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                            CupertinoActionSheetAction(
                                onPressed: () async{
                                  final res = await context.push('/select/friends');

                                  if(res != null){

                                  }
                                  nav.pop();
                                },
                                child: Text('초대', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                            if((scheduleProvider.schedule?['state'] ?? 0) < 1)
                            CupertinoActionSheetAction(
                                onPressed: (){
                                  nav.pop();
                                  context.push('/schedule/${scheduleProvider.schedule!['scheduleId']}/edit');
                                },
                                child: Text('수정', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                            if((scheduleProvider.schedule?['state'] ?? 0) < 1)
                              CupertinoActionSheetAction(
                                  onPressed: (){
                                    nav.pop();
                                    DialogManager.showBasicDialog(
                                        title: "일정 삭제 확인",
                                        content: "삭제하면 다시 복구할 수 없어요.",
                                        confirmText: "아니요, 취소할래요",
                                        cancelText: "네, 삭제할게요",
                                        onCancel: () {
                                          scheduleProvider.deleteSchedule();
                                        }
                                    );
                                  },
                                  child: Text('삭제', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                              ),
                          ]
                      );
                    });
                  }else{
                    showCupertinoModalPopup(context: context, builder: (context){
                      final nav = Navigator.of(context);
                      return NadalSheet(
                          actions: [
                            CupertinoActionSheetAction(
                                onPressed: (){
                                  nav.pop();
                                },
                                child: Text('공유', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                            CupertinoActionSheetAction(
                                onPressed: () async{
                                  final res = await context.push('/select/friends');

                                  if(res != null){

                                  }
                                  nav.pop();
                                },
                                child: Text('초대', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                            CupertinoActionSheetAction(
                                onPressed: () async{
                                  nav.pop();
                                },
                                child: Text('신고', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)
                            ),
                          ]
                      );
                    });
                  }
               },
                icon: BootstrapIcons.three_dots_vertical,
            )
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              if(scheduleProvider.schedule != null && scheduleProvider.schedule!['tag'] == "게임")
              ScheduleStepSelector(currentStep: gameProvider.currentStateView, onStepTap: (int index)=> gameProvider.setViewPage(index), stepTitles: List.generate(5, (index)=> TextFormManager.stateToText(index) ?? ''), totalSteps: 5, viewStep: gameProvider.scheduleProvider.schedule!['state'], ),
              Expanded(
                  child: scheduleProvider.schedule!['tag'] != "게임" ?
                      ScheduleMain(commentProvider: commentProvider, provider: scheduleProvider, userProvider: userProvider ) :
                      _bodyWidget(gameProvider.currentStateView)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodyWidget(int? state){
      if(state != null){
      if(gameProvider.scheduleProvider.schedule!['state'] < state){
          return GameBlock(mainText: '미공개 정보입니다!', subText: '게임 진행에따라 페이지가 오픈되요');
      }
    }

    switch(state){
      case 1: return GameState1(gameProvider: gameProvider, scheduleProvider: scheduleProvider,);
      case 2: return GameState2(gameProvider: gameProvider,);
      case 3: return GameState3(gameProvider: gameProvider,);
      case 4: return GameState4(gameProvider: gameProvider,);
      default: return ScheduleMain(commentProvider: commentProvider, provider: scheduleProvider, userProvider: userProvider,);
    }
  }
}
