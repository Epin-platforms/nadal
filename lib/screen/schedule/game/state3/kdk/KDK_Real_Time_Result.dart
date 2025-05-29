import '../../../../../manager/project/Import_Manager.dart';

class KdkRealTimeResult extends StatelessWidget {
  const KdkRealTimeResult({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);

    // 안전성 체크
    if (provider.schedule == null || provider.gameTables == null || provider.scheduleMembers == null) {
      return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '실시간 현황',
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NadalCircular(),
                SizedBox(height: 16.h),
                Text('데이터를 불러오는 중...', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    final finalScore = provider.schedule!['finalScore'] ?? 6;
    final gameList = provider.gameTables!.entries.toList()
      ..sort((a, b) => a.value['tableId'].compareTo(b.value['tableId']));
    final isSingle = provider.schedule!['isSingle'] == 1;

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '실시간 현황',
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 요약 정보
              _buildSummaryCard(context, provider, theme, finalScore, gameList),

              SizedBox(height: 16.h),

              // 순위표
              _buildRankingCard(context, provider, theme, finalScore, gameList, isSingle),

              SizedBox(height: 16.h),

              // 진행중인 게임 목록
              _buildOngoingGames(context, provider, theme, finalScore, gameList, isSingle),

              SizedBox(height: 16.h),

              // 완료된 게임 목록
              _buildCompletedGames(context, provider, theme, finalScore, gameList, isSingle),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 요약 카드
  Widget _buildSummaryCard(BuildContext context, ScheduleProvider provider, ThemeData theme, int finalScore, List<MapEntry<int, Map<String, dynamic>>> gameList) {
    final totalGames = gameList.length;
    final completedGames = gameList.where((game) {
      final score1 = (game.value['score1'] ?? 0) as int;
      final score2 = (game.value['score2'] ?? 0) as int;
      return score1 == finalScore ||
          score2 == finalScore ||
          (score1 == score2 && score1 > 0);
    }).length;
    final progressPercent = totalGames > 0 ? (completedGames / totalGames * 100).round() : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게임 진행률',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$completedGames / $totalGames',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$progressPercent%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LinearProgressIndicator(
            value: progressPercent / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ],
      ),
    );
  }

  // 순위표 카드
  Widget _buildRankingCard(BuildContext context, ScheduleProvider provider, ThemeData theme, int finalScore, List<MapEntry<int, Map<String, dynamic>>> gameList, bool isSingle) {
    final members = provider.scheduleMembers!.entries.map((e) => e.value).toList();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // 각 멤버의 실시간 승점과 득점 계산
    final membersWithStats = members.map((member) {
      final memberUid = member['uid'];
      final stats = _calculateMemberStats(memberUid, gameList, finalScore, isSingle);

      return {
        ...member,
        'calculatedWinPoint': stats['winPoint'],
        'calculatedScore': stats['totalScore'],
        'gamesPlayed': stats['gamesPlayed'],
      };
    }).toList();

    // 승점/점수 기준으로 정렬 (null 안전성 보장)
    membersWithStats.sort((a, b) {
      final aWinPoint = (a['calculatedWinPoint'] ?? 0) as int;
      final bWinPoint = (b['calculatedWinPoint'] ?? 0) as int;
      if (aWinPoint != bWinPoint) return bWinPoint.compareTo(aWinPoint);

      final aScore = (a['calculatedScore'] ?? 0) as int;
      final bScore = (b['calculatedScore'] ?? 0) as int;
      return bScore.compareTo(aScore);
    });

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary, size: 24.r),
              SizedBox(width: 8.w),
              Text('현재 순위', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 16.h),
          ...membersWithStats.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final isMe = member['uid'] == uid;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8.r),
                border: isMe ? Border.all(color: theme.colorScheme.primary, width: 1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: index < 3 ?
                      (index == 0 ? Color(0xFFFFD700) :
                      index == 1 ? Color(0xFFC0C0C0) : Color(0xFFCD7F32)) :
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: index < 3 ? Colors.white : theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TextFormManager.profileText(
                            member['nickName'],
                            member['name'],
                            member['birthYear'],
                            member['gender'],
                            useNickname: member['gender'] == null,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if ((member['gamesPlayed'] ?? 0) > 0)
                          Text(
                            '${member['gamesPlayed'] ?? 0}경기 진행',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '승점 ${member['calculatedWinPoint'] ?? 0}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '득점 ${member['calculatedScore'] ?? 0}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 진행중인 게임 목록
  Widget _buildOngoingGames(BuildContext context, ScheduleProvider provider, ThemeData theme, int finalScore, List<MapEntry<int, Map<String, dynamic>>> gameList, bool isSingle) {
    final ongoingGames = gameList.where((game) {
      final score1 = (game.value['score1'] ?? 0) as int;
      final score2 = (game.value['score2'] ?? 0) as int;
      return score1 != finalScore &&
          score2 != finalScore &&
          !(score1 == score2 && score1 > 0);
    }).toList();

    if (ongoingGames.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48.r, color: theme.colorScheme.secondary),
              SizedBox(height: 8.h),
              Text('모든 게임이 완료되었습니다', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_tennis_rounded, color: theme.colorScheme.primary, size: 24.r),
              SizedBox(width: 8.w),
              Text('진행중인 게임', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('${ongoingGames.length}경기', style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...ongoingGames.map((game) => _buildGameItem(context, provider, theme, game, isSingle, false)),
        ],
      ),
    );
  }

  // 완료된 게임 목록
  Widget _buildCompletedGames(BuildContext context, ScheduleProvider provider, ThemeData theme, int finalScore, List<MapEntry<int, Map<String, dynamic>>> gameList, bool isSingle) {
    final completedGames = gameList.where((game) {
      final score1 = (game.value['score1'] ?? 0) as int;
      final score2 = (game.value['score2'] ?? 0) as int;
      return score1 == finalScore ||
          score2 == finalScore ||
          (score1 == score2 && score1 > 0);
    }).toList();

    if (completedGames.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.secondary, size: 24.r),
              SizedBox(width: 8.w),
              Text('완료된 게임', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('${completedGames.length}경기', style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...completedGames.map((game) => _buildGameItem(context, provider, theme, game, isSingle, true)),
        ],
      ),
    );
  }

  // 게임 아이템 위젯
  Widget _buildGameItem(BuildContext context, ScheduleProvider provider, ThemeData theme, MapEntry<int, Map<String, dynamic>> game, bool isSingle, bool isCompleted) {
    final gameData = game.value;
    final player1 = provider.scheduleMembers![gameData['player1_0']];
    final player1_1 = isSingle ? null : provider.scheduleMembers![gameData['player1_1']];
    final player2 = provider.scheduleMembers![gameData['player2_0']];
    final player2_1 = isSingle ? null : provider.scheduleMembers![gameData['player2_1']];

    final score1 = (gameData['score1'] ?? 0) as int;
    final score2 = (gameData['score2'] ?? 0) as int;
    final isPlayer1Win = score1 > score2 && isCompleted;
    final isPlayer2Win = score2 > score1 && isCompleted;
    final isTie = score1 == score2 && score1 > 0 && isCompleted;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isCompleted ? theme.scaffoldBackgroundColor : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCompleted ? theme.dividerColor : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 세트 정보
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '세트 ${gameData['tableId']}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              if (gameData['coat'] != null)
                Text(
                  '${gameData['coat']} 코트',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // 대결 정보
          Row(
            children: [
              // 1팀/1번 선수
              Expanded(
                child: _buildPlayerInfo(theme, player1, player1_1, isSingle, isPlayer1Win),
              ),

              // 점수
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$score1 : $score2',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isTie ? theme.colorScheme.secondary : theme.colorScheme.primary,
                  ),
                ),
              ),

              // 2팀/2번 선수
              Expanded(
                child: _buildPlayerInfo(theme, player2, player2_1, isSingle, isPlayer2Win, isRight: true),
              ),
            ],
          ),

          // 결과 표시 (완료된 경우)
          if (isCompleted)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTie ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                    size: 16.r,
                    color: isTie ? theme.colorScheme.secondary : theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isTie ? '무승부' : (isPlayer1Win ? '1번 승리' : '2번 승리'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isTie ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 선수 정보 위젯
  Widget _buildPlayerInfo(ThemeData theme, Map player1, Map? player2, bool isSingle, bool isWinner, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          TextFormManager.profileText(
            player1['nickName'],
            player1['name'],
            player1['birthYear'],
            player1['gender'],
            useNickname: player1['gender'] == null,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            color: isWinner ? theme.colorScheme.primary : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isRight ? TextAlign.end : TextAlign.start,
        ),
        if (!isSingle && player2 != null)
          Text(
            TextFormManager.profileText(
              player2['nickName'],
              player2['name'],
              player2['birthYear'],
              player2['gender'],
              useNickname: player2['gender'] == null,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isWinner ? FontWeight.w600 : FontWeight.w500,
              color: isWinner ? theme.colorScheme.primary : theme.hintColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isRight ? TextAlign.end : TextAlign.start,
          ),
      ],
    );
  }

  // 실시간 개인 통계 계산 헬퍼 메서드
  Map<String, int> _calculateMemberStats(String memberUid, List<MapEntry<int, Map<String, dynamic>>> gameList, int finalScore, bool isSingle) {
    int winPoint = 0;
    int totalScore = 0;
    int gamesPlayed = 0;

    // 해당 멤버가 참여한 게임들을 찾기
    final memberGames = gameList.where((game) {
      if (isSingle) {
        return game.value['player1_0'] == memberUid || game.value['player2_0'] == memberUid;
      } else {
        return game.value['player1_0'] == memberUid ||
            game.value['player1_1'] == memberUid ||
            game.value['player2_0'] == memberUid ||
            game.value['player2_1'] == memberUid;
      }
    }).toList();

    // 각 게임별 승점과 득점 계산
    for (final game in memberGames) {
      final score1 = (game.value['score1'] ?? 0) as int;
      final score2 = (game.value['score2'] ?? 0) as int;

      // 게임이 완료된 경우만 계산
      if (score1 == finalScore || score2 == finalScore || (score1 == score2 && score1 > 0)) {
        gamesPlayed++;

        bool isPlayer1Side;
        if (isSingle) {
          isPlayer1Side = game.value['player1_0'] == memberUid;
        } else {
          isPlayer1Side = game.value['player1_0'] == memberUid || game.value['player1_1'] == memberUid;
        }

        final myScore = isPlayer1Side ? score1 : score2;
        final opponentScore = isPlayer1Side ? score2 : score1;
        final scoreDifference = myScore - opponentScore;

        // 승점 계산 (승리시에만 1점)
        if (myScore > opponentScore) {
          winPoint += 1;
        }

        // 득점 계산 (점수차 누적)
        totalScore += scoreDifference;
      }
    }

    return {
      'winPoint': winPoint,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
    };
  }
}