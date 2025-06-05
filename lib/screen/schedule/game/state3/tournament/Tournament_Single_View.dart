import 'dart:math';

import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/screen/schedule/game/state3/tournament/Walk_Over_Card.dart';

import '../../../../../manager/project/Import_Manager.dart';
import 'Wait_Pre_Round.dart';

class TournamentSingleView extends StatefulWidget {
  const TournamentSingleView({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
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
    super.initState();
    _initializeRoundData();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _setupScheduleListener();
    });
  }

  void _initializeRoundData() {
    final gameTables = widget.scheduleProvider.gameTables;
    if (gameTables == null || gameTables.isEmpty) {
      _roundList = [];
      _lastRound = 1;
    } else {
      _roundList = gameTables.entries.map((e) => (e.value['tableId'] ~/ 1000) as int).toList();
      _lastRound = _roundList.isEmpty ? 1 : _roundList.reduce((a, b) => a > b ? a : b);
    }
    finalScore = widget.scheduleProvider.schedule?['finalScore'] ?? 6;
  }

  void _setupScheduleListener() {
    widget.scheduleProvider.addListener(_onScheduleDataChanged);
  }

  void _onScheduleDataChanged() {
    if (mounted) {
      _initializeRoundData();
      _calculateCurrentRound();
    }
  }

  @override
  void dispose() {
    widget.scheduleProvider.removeListener(_onScheduleDataChanged);
    super.dispose();
  }

  void _calculateCurrentRound() {
    final tables = widget.scheduleProvider.gameTables;
    if (tables == null || tables.isEmpty) {
      if (mounted) {
        setState(() {
          _currentRound = 1;
        });
      }
      return;
    }

    final List<int> roundsList = tables.entries
        .map((e) => (e.value['tableId'] ~/ 1000) as int)
        .toList();

    if (roundsList.isEmpty) {
      if (mounted) {
        setState(() {
          _currentRound = 1;
        });
      }
      return;
    }

    final maxRound = roundsList.reduce((a, b) => a > b ? a : b);
    final currentFinalScore = widget.scheduleProvider.schedule?['finalScore'] ?? 6;

    int targetRound = 1;

    for (int round = 1; round <= maxRound; round++) {
      final roundTables = tables.entries
          .where((e) => e.value['tableId'] ~/ 1000 == round)
          .map((e) => e.value)
          .toList();

      if (roundTables.isEmpty) continue;

      // 부전승 테이블 자동 완료 처리
      final nonByeTables = roundTables.where((table) => !_isAutoWinTable(table)).toList();

      final allCompleted = nonByeTables.every((table) =>
      table['score1'] == currentFinalScore || table['score2'] == currentFinalScore);

      if (!allCompleted) {
        targetRound = round;
        break;
      }

      if (round < maxRound) {
        final nextRoundTables = tables.entries
            .where((e) => e.value['tableId'] ~/ 1000 == round + 1)
            .map((e) => e.value)
            .toList();

        if (nextRoundTables.isNotEmpty) {
          final allPlayersAssigned = nextRoundTables.every((table) =>
          table['player1_0'] != null &&
              table['player1_0'] != '' &&
              table['player2_0'] != null &&
              table['player2_0'] != '');

          if (!allPlayersAssigned) {
            targetRound = round;
            break;
          }
        }
      }

      if (round == maxRound) {
        targetRound = round;
      }
    }

    if (mounted && _currentRound != targetRound) {
      setState(() {
        _currentRound = targetRound;
      });
    }
  }

  bool _isPlayerBye(String? playerId) {
    if (playerId == null || playerId.isEmpty) return false;
    return widget.scheduleProvider.byePlayers.contains(playerId);
  }

  bool _isWalkOver(Map gameData) {
    final player1Id = gameData['player1_0'];
    final player2Id = gameData['player2_0'];

    // 한 쪽이 null이거나 빈 문자열인 경우
    if (player1Id == null || player1Id == '' || player2Id == null || player2Id == '') {
      return true;
    }

    // 첫 라운드에서만 부전승 플레이어 체크
    final round = gameData['tableId'] ~/ 1000;
    if (round == 1) {
      return _isPlayerBye(player1Id) || _isPlayerBye(player2Id);
    }

    return false;
  }

  // 자동 승리 테이블인지 확인 (부전승 포함)
  bool _isAutoWinTable(Map gameData) {
    final player1Id = gameData['player1_0'];
    final player2Id = gameData['player2_0'];
    final round = gameData['tableId'] ~/ 1000;

    // 첫 라운드에서만 부전승 체크
    if (round == 1) {
      if (player1Id == null || player1Id == '' || player2Id == null || player2Id == '') {
        return true;
      }
      return _isPlayerBye(player1Id) || _isPlayerBye(player2Id);
    }

    // 다른 라운드에서는 플레이어가 없는 경우만
    return player1Id == null || player1Id == '' || player2Id == null || player2Id == '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameTable = widget.scheduleProvider.gameTables?.entries.map((e) => e.value).toList() ?? [];
    gameTable.sort((a, b) => a['tableId'].compareTo(b['tableId']));
    _calculateCurrentRound();
    final isProgress = widget.scheduleProvider.schedule?['state'] == 3;
    final uid = context.read<UserProvider>().user?['uid'];
    final isOwner = uid == widget.scheduleProvider.schedule?['uid'];
    final isLastRound = _lastRound == _currentRound;
    final rounds = gameTable.isEmpty ? 0 : gameTable.map((e){return e['tableId'] ~/ 1000;}).toSet().length;

    if (_roundList.isEmpty) {
      return SafeArea(
        child: Center(
          child: Text('게임 데이터가 없습니다.', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.1,
                  maxScale: 2.5,
                  boundaryMargin: EdgeInsets.all(100.r),
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(rounds+1, (round) {
                        final roundTables = gameTable.where((e) => e['tableId'] ~/ 1000 == round + 1).toList();
                        return AbsorbPointer(
                          absorbing: !isProgress,
                          child: SizedBox(
                            width: 240.w,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 40.h,
                                  child: Center(
                                    child: ChoiceChip(
                                      label: Text(
                                        _getRoundName(round + 1),
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: _currentRound == round + 1 ? Colors.white : theme.colorScheme.primary,
                                        ),
                                      ),
                                      selected: _currentRound == round + 1,
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      avatarBorder: CircleBorder(),
                                      avatar: _currentRound == round + 1
                                          ? Icon(Icons.check_circle, color: theme.colorScheme.onPrimary, size: 16.r)
                                          : null,
                                      onSelected: (_) {},
                                    ),
                                  ),
                                ),
                                ...List.generate(rounds == round ? 1 : roundTables.length, (index) {
                                  final itemHeight = 120.0 * pow(2, round);

                                  if (rounds <= round) {
                                    final lastId = (_lastRound * 1000) + 1;
                                    final finalGame = widget.scheduleProvider.gameTables?[lastId];

                                    if (finalGame == null) {
                                      return SizedBox(height: itemHeight);
                                    }

                                    return SizedBox(
                                      height: itemHeight,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            height: 90.h,
                                            width: 200.w,
                                            decoration: BoxDecoration(
                                                color: finalGame['score1'] == finalScore || finalGame['score2'] == finalScore ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                borderRadius: BorderRadius.circular(15.r),
                                                boxShadow: [
                                                  if (finalGame['score1'] == finalScore || finalGame['score2'] == finalScore)
                                                    BoxShadow(
                                                        color: theme.highlightColor,
                                                        blurRadius: 10,
                                                        spreadRadius: 0)
                                                ]),
                                            child: finalGame['score1'] == finalScore || finalGame['score2'] == finalScore
                                                ? Padding(
                                                padding: EdgeInsets.all(12.r),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                        child: _playerCard(
                                                            finalGame['score1'] == finalScore ? finalGame['player1_0'] : finalGame['player2_0'], finalGame)),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(15.r),
                                                        color: const Color(0xFFFFD700),
                                                      ),
                                                      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
                                                      child: Text(
                                                        'WIN',
                                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xffffffff)),
                                                      ),
                                                    ),
                                                  ],
                                                ))
                                                : WaitPreRound()),
                                      ),
                                    );
                                  }

                                  if (index >= roundTables.length) {
                                    return SizedBox(height: itemHeight);
                                  }

                                  final game = roundTables[index];
                                  final isWalkOverGame = _isWalkOver(game);
                                  final gameRound = game['tableId'] ~/ 1000;

                                  return AbsorbPointer(
                                    absorbing: round + 1 != _currentRound,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: itemHeight,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Center(
                                                child: Container(
                                                    height: 90.h,
                                                    width: 200.w,
                                                    decoration: BoxDecoration(
                                                        color: game['player1_0'] != null && game['player1_0'] != '' ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                        borderRadius: BorderRadius.circular(12.r),
                                                        border: game['score1'] == finalScore || game['score2'] == finalScore
                                                            ? game['score1'] == finalScore
                                                            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2)
                                                            : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2)
                                                            : Border.all(color: theme.highlightColor, width: 2),
                                                        boxShadow: [
                                                          if (game['player1_0'] != null && game['player1_0'] != '')
                                                            BoxShadow(color: theme.highlightColor, blurRadius: 10, spreadRadius: 0)
                                                        ]),
                                                    child: game['player1_0'] != null && game['player1_0'] != ''
                                                        ? InkWell(
                                                      borderRadius: BorderRadius.circular(12.r),
                                                      onTap: isWalkOverGame ? null : () async {
                                                        if(!widget.scheduleProvider.scheduleMembers!.containsKey(FirebaseAuth.instance.currentUser!.uid)) return; //만약 사용자가 참가자가아니라면 점수입력 금지
                                                        // 부전승 플레이어는 점수 입력 불가
                                                        if (gameRound == 1 && _isPlayerBye(game['player1_0'])) {
                                                          return;
                                                        }

                                                        final score1 = await GameManager.scoreInput(finalScore, game['score1']);

                                                        if (score1 == game['score2']) {
                                                          DialogManager.showBasicDialog(title: '잠깐만요!', content: '토너먼트에서 동점기입은 불가해요', confirmText: '알겠어요');
                                                          return;
                                                        }

                                                        if (score1 != null && score1 != game['score1']) {
                                                          widget.scheduleProvider.updateScore(game['tableId'], score1, 1);
                                                        }
                                                      },
                                                      child: Padding(
                                                          padding: EdgeInsets.all(12.r),
                                                          child: Row(
                                                            children: [
                                                              Expanded(child: _playerCard(game['player1_0'], game)),
                                                              // 부전승이 아닐 때만 점수 표시
                                                              if (!(gameRound == 1 && _isPlayerBye(game['player1_0'])))
                                                                Container(
                                                                  padding: EdgeInsets.all(5.r),
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: theme.colorScheme.secondary,
                                                                  ),
                                                                  child: Text(
                                                                    '${game['score1']}',
                                                                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary),
                                                                  ),
                                                                )
                                                            ],
                                                          )),
                                                    )
                                                        : gameRound == 1 ? WalkOverCard() : WaitPreRound()),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: itemHeight / 2,
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                            color: game['score1'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor, width: 2.5),
                                                        right: BorderSide(
                                                            color: game['score1'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor, width: 2.5),
                                                      )),
                                                ),
                                              ),
                                              Container(
                                                height: 1.25,
                                                width: 15.w,
                                                color: game['score1'] == finalScore || game['score2'] == finalScore
                                                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                                    : theme.highlightColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: itemHeight,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Container(
                                                    height: 90.h,
                                                    width: 200.w,
                                                    decoration: BoxDecoration(
                                                        color: game['player2_0'] != null && game['player2_0'] != '' ? theme.scaffoldBackgroundColor : theme.highlightColor,
                                                        borderRadius: BorderRadius.circular(15.r),
                                                        border: game['score1'] == finalScore || game['score2'] == finalScore
                                                            ? game['score2'] == finalScore
                                                            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.7), width: 2)
                                                            : Border.all(color: theme.colorScheme.onError.withValues(alpha: 0.2), width: 2)
                                                            : Border.all(color: theme.highlightColor, width: 2),
                                                        boxShadow: [
                                                          if (game['player2_0'] != null && game['player2_0'] != '')
                                                            BoxShadow(color: theme.highlightColor, blurRadius: 10, spreadRadius: 0)
                                                        ]),
                                                    child: game['player2_0'] != null && game['player2_0'] != ''
                                                        ? InkWell(
                                                      borderRadius: BorderRadius.circular(12.r),
                                                      onTap: isWalkOverGame ? null : () async {
                                                        if(!widget.scheduleProvider.scheduleMembers!.containsKey(FirebaseAuth.instance.currentUser!.uid)) return; //만약 사용자가 참가자가아니라면 점수입력 금지
                                                        // 부전승 플레이어는 점수 입력 불가
                                                        if (gameRound == 1 && _isPlayerBye(game['player2_0'])) {
                                                          return;
                                                        }

                                                        final score2 = await GameManager.scoreInput(finalScore, game['score2']);

                                                        if (score2 == game['score1']) {
                                                          DialogManager.showBasicDialog(title: '잠깐만요!', content: '토너먼트에서 동점기입은 불가해요', confirmText: '알겠어요');
                                                          return;
                                                        }

                                                        if (score2 != null && score2 != game['score2']) {
                                                          widget.scheduleProvider.updateScore(game['tableId'], score2, 2);
                                                        }
                                                      },
                                                      child: Padding(
                                                          padding: EdgeInsets.all(12.r),
                                                          child: Row(
                                                            children: [
                                                              Expanded(child: _playerCard(game['player2_0'], game)),
                                                              // 부전승이 아닐 때만 점수 표시
                                                              if (!(gameRound == 1 && _isPlayerBye(game['player2_0'])))
                                                                Container(
                                                                  padding: EdgeInsets.all(5.r),
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: theme.colorScheme.secondary,
                                                                  ),
                                                                  child: Text(
                                                                    '${game['score2']}',
                                                                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.onSecondary),
                                                                  ),
                                                                )
                                                            ],
                                                          )),
                                                    )
                                                        : gameRound == 1 ? WalkOverCard() : WaitPreRound()),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: itemHeight / 2,
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: game['score2'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor, width: 2.5),
                                                        right: BorderSide(
                                                            color: game['score2'] == finalScore ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.highlightColor, width: 2.5),
                                                      )),
                                                ),
                                              ),
                                              Container(
                                                height: 1.25,
                                                width: 15.w,
                                                color: game['score1'] == finalScore || game['score2'] == finalScore
                                                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                                    : theme.highlightColor,
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
                  ))),
          if (isOwner && isProgress)
            NadalButton(
              onPressed: () {
                final currentRoundGame = gameTable.where((element) => element['tableId'] ~/ 1000 == _currentRound);

                // 부전승이 아닌 실제 게임만 체크
                final realGames = currentRoundGame.where((element) => !_isAutoWinTable(element));

                final isEnd = realGames
                    .where((element) =>
                (element['score1'] != finalScore && element['score2'] != finalScore) ||
                    (element['score1'] == finalScore && element['score1'] == element['score2']))
                    .isEmpty;

                if (!isEnd) {
                  DialogManager.showBasicDialog(
                      title: '조금만 더 기다려주세요!', content: '아직 끝나지 않은 경기가 있어요.\n모두 종료되면 다음으로 넘어갈 수 있어요.', confirmText: '알겠어요');
                  return;
                }

                if (isLastRound) {
                  DialogManager.showBasicDialog(
                      onConfirm: () {
                        widget.scheduleProvider.endGame();
                      },
                      title: '게임 끝낼까요?',
                      content: '종료하면 기록은 저장되고 수정은 안 돼요!',
                      confirmText: '게임 종료!',
                      cancelText: '잠깐만요!');
                } else {
                  DialogManager.showBasicDialog(
                      onConfirm: () async{
                        widget.scheduleProvider.nextRound(_currentRound);
                      },
                      title: '이 라운드 확정해도 괜찮을까요?',
                      content: '한 번 확정하면 수정은 어렵습니다!',
                      confirmText: '다음 라운드 시작!',
                      cancelText: '잠깐만요!');
                }
              },
              isActive: true,
              title: isLastRound ? '토너먼트를 종료하기' : '${_getRoundName(_currentRound)} 확정하기',
            )
        ],
      ),
    );
  }

  String _getRoundName(int round) {
    // totalSlots 기반으로 강 수 계산 (2의 제곱수)
    final totalSlots = widget.scheduleProvider.totalSlots;
    if (totalSlots <= 0) return '라운드 $round';

    final num = totalSlots ~/ pow(2, round - 1);
    return num == 2
        ? '결승'
        : num == 4
        ? '준결승'
        : num == 1
        ? '우승'
        : '$num강';
  }

  Widget _playerCard(String? uid, Map game) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final scheduleMembers = widget.scheduleProvider.scheduleMembers;
      final gameRound = game['tableId'] ~/ 1000;

      if (uid == null || uid.isEmpty || scheduleMembers == null || !scheduleMembers.containsKey(uid)) {
        // 첫 라운드가 아니면 "대기 중" 표시
        if (gameRound > 1) {
          return Center(
            child: Text(
              '대기 중',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        // 첫 라운드에서만 "부전승" 표시
        return Center(
          child: Text(
            '부전승',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      final player = scheduleMembers[uid];
      final isByePlayer = gameRound == 1 && _isPlayerBye(uid); // 첫 라운드에서만 부전승 체크

      return Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              Text(
                '${player['memberIndex']}.',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isByePlayer ? theme.colorScheme.error : theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isByePlayer
                          ? '${TextFormManager.profileText(
                        player['nickName'],
                        player['name'],
                        player['birthYear'],
                        player['gender'],
                        useNickname: player['gender'] == null,
                      )} (부전승)'
                          : TextFormManager.profileText(
                        player['nickName'],
                        player['name'],
                        player['birthYear'],
                        player['gender'],
                        useNickname: player['gender'] == null,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isByePlayer ? theme.colorScheme.error : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ));
    });
  }
}