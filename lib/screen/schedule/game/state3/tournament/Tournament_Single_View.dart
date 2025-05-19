import 'dart:math';

import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/provider/game/Game_Provider.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Walk_Over_Card.dart';

import '../../../../../manager/project/Import_Manager.dart';
import 'Wait_Pre_Round.dart';

class TournamentSingleView extends StatefulWidget {
  const TournamentSingleView({super.key, required this.gameProvider});
  final GameProvider gameProvider;

  @override
  State<TournamentSingleView> createState() => _TournamentSingleViewState();
}

class _TournamentSingleViewState extends State<TournamentSingleView> {
  late final List<int> _roundList;
  late final int _lastRound;
  late int finalScore;
  int _currentRound = 1;

  @override
  void initState() {
    _roundList = widget.gameProvider.tables!.entries.map((e) => (e.value['tableId'] ~/ 1000) as int).toList();
    _lastRound = _roundList.isEmpty ? 1 : _roundList.reduce((a,b) => a > b ? a : b);
    finalScore = widget.gameProvider.scheduleProvider.schedule!['finalScore'];
    WidgetsBinding.instance.addPostFrameCallback((_)=> _calculateCurrentRound());
    super.initState();
  }

  void _calculateCurrentRound() {
    // 가장 높은 라운드 중 모든 매치가 완료되지 않은 라운드를 현재 라운드로 설정
    final tables = widget.gameProvider.tables;
    if (tables == null || tables.isEmpty) return;

    final List<int> roundsList = tables.entries
        .map((e) => (e.value['tableId'] ~/ 1000) as int)
        .toList();
    final maxRound = roundsList.isEmpty ? 1 : roundsList.reduce((a, b) => a > b ? a : b);
    final finalScore = widget.gameProvider.scheduleProvider.schedule?['finalScore'] ?? 6;

    for (int round = 1; round <= maxRound; round++) {
      final roundTables = tables.entries
          .where((e) => e.value['tableId'] ~/ 1000 == round)
          .map((e) => e.value);

      // 현재 라운드의 모든 경기가 완료되었는지 확인
      final allCompleted = roundTables.every((table) =>
      table['score1'] == finalScore || table['score2'] == finalScore);

      if (!allCompleted) {
        setState(() {
          _currentRound = round;
        });
        break;
      }

      // 현재 라운드의 모든 경기가 완료된 경우, 다음 라운드에 선수가 배치되었는지 확인
      if (round < maxRound) {
        final nextRoundTables = tables.entries
            .where((e) => e.value['tableId'] ~/ 1000 == round + 1)
            .map((e) => e.value);

        // 다음 라운드에 선수가 모두 배치되었는지 확인
        final allPlayersAssigned = nextRoundTables.every((table) =>
        table['player1_0'] != null &&
            table['player1_0'] != '' &&
            table['player2_0'] != null &&
            table['player2_0'] != '');

        // 다음 라운드에 선수가 배치되지 않았으면 현재 라운드로 설정
        if (!allPlayersAssigned) {
          setState(() {
            _currentRound = round;
          });
          break;
        }
      }

      // 마지막 라운드이고 모든 경기가 완료된 경우
      if (round == maxRound && allCompleted) {
        setState(() {
          _currentRound = round;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    //게임 테이블
    final gameTable = widget.gameProvider.tables!.entries.map((e)=> e.value).toList();
    gameTable.sort((a,b)=> a['tableId'].compareTo(b['tableId']));

    //기타 내용
    final isProgress = widget.gameProvider.scheduleProvider.schedule?['state'] == 3;
    final uid = context.read<UserProvider>().user?['uid'];
    final isOwner = uid == widget.gameProvider.scheduleProvider.schedule?['uid'];
    final isLastRound = _lastRound == _currentRound;
    final rounds = gameTable.map((e)=> e['tableId'] ~/ 1000).toSet().length;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
              child: InteractiveViewer(
                  constrained: false, // 내부 위젯 크기 제한 없음
                  minScale: 0.1,      // 최소 축소 비율
                  maxScale: 2.5,      // 최대 확대 비율
                  boundaryMargin: const EdgeInsets.all(100), // 밖으로 패닝 허용
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(_roundList.length, (round){
                        final roundTables = gameTable.where((e)=> e['tableId'] ~/ 1000 == round + 1).toList();
                        return AbsorbPointer(
                          absorbing: !isProgress,
                          child: SizedBox(
                            width: 240,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: ChoiceChip(
                                      label: Text(
                                        _getRoundName(round+1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _currentRound == round + 1  ? Colors.white : theme.colorScheme.primary,
                                        ),
                                      ),
                                      selected: _currentRound == round + 1,
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      avatarBorder: CircleBorder(),
                                      avatar: _currentRound == round + 1
                                          ? Icon(Icons.check_circle, color: theme.colorScheme.onPrimary, size: 16)
                                          : null,
                                      onSelected: (_) {},
                                    ),
                                  ),
                                ),
                                ...List.generate(rounds == round ? 1 : roundTables.length, (index){
                                  final itemHeight = 120 * pow(2, round);

                                  if(rounds <= round){
                                    final lastId =  (_lastRound * 1000) + 1;
                                    final finalGame = widget.gameProvider.tables![lastId]!;
                                    return   SizedBox(
                                      height: (120 * pow(2, round)).toDouble(),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            height: 90,
                                            width: 200,
                                            decoration: BoxDecoration(
                                                color: finalGame['score1'] == finalScore || finalGame['score2'] == finalScore ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                borderRadius: BorderRadius.circular(15),
                                                boxShadow: [
                                                  if(finalGame['score1'] == finalScore || finalGame['score2'] == finalScore)
                                                    BoxShadow(
                                                        color: theme.highlightColor,
                                                        blurRadius: 10,
                                                        spreadRadius: 0
                                                    )
                                                ]
                                            ),
                                            child: finalGame['score1'] == finalScore || finalGame['score2'] == finalScore ?
                                            Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: _playerCard(finalGame['score1'] == finalScore ? finalGame['player1_0'] : finalGame['player2_0'], finalGame)
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(15),
                                                        color: const Color(0xFFFFD700),
                                                      ),
                                                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                                      child: Text('WIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xffffffff)),),
                                                    ),
                                                  ],
                                                ))
                                                :
                                            WaitPreRound()
                                        ),
                                      ),
                                    );
                                  }

                                  final game = roundTables[index];
                                  return AbsorbPointer(
                                    absorbing: round+1 != _currentRound,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: itemHeight.toDouble(),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Center(
                                                child: Container(
                                                    height: 90,
                                                    width: 200,
                                                    decoration: BoxDecoration(
                                                        color: game['player1_0'] != null ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: game['score1'] == finalScore || game['score2'] == finalScore ?
                                                        game['score1'] == finalScore ?
                                                        Border.all(
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                                            width: 2
                                                        ) :
                                                        Border.all(
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                                            width: 2
                                                        )
                                                            : Border.all(
                                                            color: theme.highlightColor,
                                                            width: 2
                                                        ),
                                                        boxShadow: [
                                                          if(game['player1_0'] != null)
                                                            BoxShadow(
                                                                color: theme.highlightColor,
                                                                blurRadius: 10,
                                                                spreadRadius: 0
                                                            )
                                                        ]
                                                    ),
                                                    child:
                                                    game['player1_0'] != null ?
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(12),
                                                      onTap: () async{
                                                        final score1 = await GameManager.scoreInput(finalScore, game['score1']);

                                                        if(score1 == game['score1']){
                                                          DialogManager.showBasicDialog(title: '잠깐만요!', content: '토너먼트에서 동점기입은 불가해요', confirmText: '알겠어요');
                                                          return;
                                                        }

                                                        if(score1 != null && score1 != game['score1']){
                                                          widget.gameProvider.onChangedScore(game['tableId'], score1, 1);
                                                        }
                                                      },
                                                      child: Padding(
                                                          padding: EdgeInsets.all(12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(child: _playerCard(game['player1_0'], game)),
                                                              Container(
                                                                padding: EdgeInsets.all(5),
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: theme.colorScheme.secondary,
                                                                ),
                                                                child: Text('${game['score1']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary),),
                                                              )
                                                            ],
                                                          )),
                                                    )
                                                        :
                                                    game['overWalk'] == true ?
                                                    WalkOverCard()
                                                        : WaitPreRound()
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: itemHeight / 2,
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                            color: game['score1'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor,
                                                            width: 2.5
                                                        ),
                                                        right: BorderSide(
                                                            color: game['score1'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor,
                                                            width: 2.5
                                                        ),
                                                      )
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 1.25, width: 15,
                                                color: game['score1'] == finalScore || game['score2'] == finalScore ?  theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: itemHeight.toDouble(),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Container(
                                                    height: 90,
                                                    width: 200,
                                                    decoration: BoxDecoration(
                                                        color: game['player2_0'] != null ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                        borderRadius: BorderRadius.circular(15),
                                                        border: game['score1'] == finalScore || game['score2'] == finalScore ?
                                                        game['score2'] == finalScore ?
                                                        Border.all(
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                                            width: 2
                                                        ) :
                                                        Border.all(
                                                            color: theme.colorScheme.onError.withValues(alpha: 0.2),
                                                            width: 2
                                                        )
                                                            : Border.all(
                                                            color: theme.highlightColor,
                                                            width: 2
                                                        ),
                                                        boxShadow: [
                                                          if(game['player2_0'] != null)
                                                            BoxShadow(
                                                                color: theme.highlightColor,
                                                                blurRadius: 10,
                                                                spreadRadius: 0
                                                            )
                                                        ]
                                                    ),
                                                    child: game['player2_0'] != null ?
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(12),
                                                      onTap: () async{
                                                        final score1 = await GameManager.scoreInput(finalScore, game['score1']);

                                                        if(score1 == game['score1']){
                                                          DialogManager.showBasicDialog(title: '잠깐만요!', content: '토너먼트에서 동점기입은 불가해요', confirmText: '알겠어요');
                                                          return;
                                                        }

                                                        if(score1 != null && score1 != game['score1']){
                                                          widget.gameProvider.onChangedScore(game['tableId'], score1, 1);
                                                        }
                                                      },
                                                      child: Padding(
                                                          padding: EdgeInsets.all(12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(child: _playerCard(game['player2_0'], game)),
                                                              Container(
                                                                padding: EdgeInsets.all(5),
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: theme.colorScheme.secondary,
                                                                ),
                                                                child: Text('${game['score2']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary),),
                                                              )
                                                            ],
                                                          )),
                                                    )
                                                        :
                                                    game['overWalk'] == true ?
                                                    WalkOverCard()   :
                                                    WaitPreRound()
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: itemHeight / 2,
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: game['score2'] ==  finalScore ? theme.colorScheme.onPrimary : theme.highlightColor,
                                                            width: 2.5
                                                        ),
                                                        right: BorderSide(
                                                            color: game['score2'] == finalScore ? theme.colorScheme.onPrimary : theme.highlightColor,
                                                            width: 2.5
                                                        ),
                                                      )
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 1.25, width: 15,
                                                color: game['score1'] == finalScore || game['score2'] == finalScore ?  theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  )
              )
          ),
          if (isOwner && isProgress)
            NadalButton(
              onPressed: (){
                final currentRoundGame = gameTable.where((element) => element['tableId'] ~/ 1000 == _currentRound);
                final isEnd = currentRoundGame.where((element) =>
                (element['score1'] != finalScore && element['score2'] != finalScore) //둘다 최종 스코어에 도달하지 못한 경우
                    || (element['score1'] == finalScore && element['score1'] == element['score2']) //둘다 최종 스코어에 도달한 경우
                ).isEmpty;

                if(!isEnd){ //끝나지 않았다면
                  DialogManager.showBasicDialog(title: '조금만 더 기다려주세요!', content: '아직 끝나지 않은 경기가 있어요.\n모두 종료되면 다음으로 넘어갈 수 있어요.', confirmText: '알겠어요');
                  return;
                }

                if(isLastRound){
                  DialogManager.showBasicDialog(
                      onConfirm: (){
                        widget.gameProvider.endGame();
                      },
                      title: '게임 끝낼까요?', content: '종료하면 기록은 저장되고 수정은 안 돼요!', confirmText: '게임 종료!', cancelText: '잠깐만요!');
                }else{
                  DialogManager.showBasicDialog(
                      onConfirm: (){
                        widget.gameProvider.nextRound(_currentRound);
                      },
                      title: '이 라운드 확정해도 괜찮을까요?', content: '한 번 확정하면 수정은 어렵습니다!', confirmText: '다음 라운드 시작!', cancelText: '잠깐만요!' );
                }
              },
              isActive: true,
              title: isLastRound ? '토너먼트를 종료하기' :
              '${_getRoundName(_currentRound)} 확정하기',)
        ],
      ),
    );
  }

  String _getRoundName(int round){
    final num = widget.gameProvider.scheduleProvider.scheduleMembers!.length ~/ pow(2, round-1);
    return num == 2 ? '결승' :
    num == 4 ? '준결승' :
    num == 1 ? '우승' :
    '$num강';
  }

  Widget _playerCard(String uid, Map game){
    return Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final player = widget.gameProvider.scheduleProvider.scheduleMembers![uid];
          return Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // 선수 번호
                  Text(
                    '${player['memberIndex']}.',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 선수 이름
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          TextFormManager.profileText(
                            player['nickName'],
                            player['name'],
                            player['birthYear'],
                            player['gender'],
                            useNickname: player['gender'] == null,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
          );
        }
    );
  }
}
