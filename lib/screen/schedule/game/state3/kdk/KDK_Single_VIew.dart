import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/widget/Nadal_Court_Input.dart';

import '../../../../../manager/project/Import_Manager.dart';

class KdkSingleView extends StatefulWidget {
  const KdkSingleView({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  State<KdkSingleView> createState() => _KdkSingleViewViewState();
}

class _KdkSingleViewViewState extends State<KdkSingleView> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final isProgress = widget.scheduleProvider.schedule!['state'] == 3;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final int finalScore = widget.scheduleProvider.schedule!['finalScore'] ?? 6;
    final bool isEnd = widget.scheduleProvider.gameTables!.entries.where((e) =>
    e.value['score1'] == finalScore ||
        e.value['score2'] == finalScore ||
        (e.value['score1'] == e.value['score2'] && e.value['score1'] != 0)
    ).length == widget.scheduleProvider.gameTables!.entries.length;

    return Column(
      children: [
        // 상단 정보 영역
        // 상단 정보 영역
        if (isProgress)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isEnd
                  ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                  : theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnd
                    ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEnd
                      ? Icons.sports_score_rounded
                      : Icons.sports_tennis_rounded,
                  color: isEnd
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  size: 20.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    isEnd
                        ? '모든 게임이 종료되었습니다. 결과를 확정해주세요.'
                        : '게임이 진행 중입니다. 완료된 세트의 점수를 입력해주세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isEnd
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // 여기에 실시간 보기 버튼 추가
                ElevatedButton.icon(
                  onPressed: () {
                    // 실시간 진행 보기 페이지로 이동
                    HapticFeedback.mediumImpact();
                    context.push('/live-match-view'); // 적절한 라우트로 변경
                  },
                  icon: Icon(BootstrapIcons.trophy_fill, size: 16.r, color: theme.colorScheme.onSurface,),
                  label: Text('실시간 결과' , style: theme.textTheme.labelMedium,),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:  EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    minimumSize:  Size(0, 36.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 게임 목록
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 50),
            itemCount: widget.scheduleProvider.gameTables!.entries.length,
            separatorBuilder: (BuildContext context, int index) =>
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
            itemBuilder: (context, index) {
              final item = widget.scheduleProvider.gameTables!.entries.toList()[index];
              final player1 = widget.scheduleProvider.scheduleMembers![item.value['player1_0']];
              final player2 = widget.scheduleProvider.scheduleMembers![item.value['player2_0']];
              final int myIndex = item.value['player1_0'] == uid ? 1 : item.value['player2_0'] == uid ? 2 : -1;

              // 게임 결과 확인
              final bool isPlayer1Win = item.value['score1'] == finalScore && item.value['score1'] != item.value['score2'];
              final bool isPlayer2Win = item.value['score2'] == finalScore && item.value['score1'] != item.value['score2'];
              final bool isTie = item.value['score1'] == item.value['score2'] && item.value['score1'] == 6;
              final bool isMatchComplete = isPlayer1Win || isPlayer2Win || isTie;

              return IgnorePointer(
                ignoring: !isProgress,
                child: Container(
                  margin:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 세트 & 코트 정보
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
                        child: Row(
                          children: [
                            // 세트 정보
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.value['tableId']} 세트',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            SizedBox(width: 10.w),

                            // 코트 정보
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 16.r,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4.w),

                                  if (widget.scheduleProvider.courtInputTableId == item.value['tableId'])
                                    Expanded(
                                      child: NadalCourtInput(
                                        controller: widget.scheduleProvider.courtController!,
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: Text(
                                        item.value['court'] == null ? '코트 미지정' : '${item.value['court']} 코트',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 코트 편집 버튼
                            if (widget.scheduleProvider.courtInputTableId == null)
                              IconButton(
                                onPressed: () {
                                  widget.scheduleProvider.setCourtInput(item.value['tableId']);
                                  HapticFeedback.lightImpact();
                                },
                                icon:  Icon(Icons.edit_rounded, size: 18.r),
                                color: theme.colorScheme.primary,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 36.w,
                                  minHeight: 36.h,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            else if (widget.scheduleProvider.courtInputTableId == item.value['tableId'])
                              TextButton(
                                onPressed: () {
                                  final court = widget.scheduleProvider.courtController!.text;
                                  if (court.isNotEmpty && court != item.value['court']) {
                                    widget.scheduleProvider.updateCourt(item.value['tableId'], court);
                                  }
                                  widget.scheduleProvider.setCourtInput(null);
                                  HapticFeedback.mediumImpact();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                ),
                                child: Text(
                                  '저장',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 게임 결과 표시 (완료된 경우)
                      if (isMatchComplete)
                        Container(
                          margin:  EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                          padding:  EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isPlayer1Win || isPlayer2Win
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : theme.colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPlayer1Win || isPlayer2Win
                                    ? Icons.emoji_events_rounded
                                    : Icons.handshake_rounded,
                                size: 14,
                                color: isPlayer1Win || isPlayer2Win
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                isPlayer1Win
                                    ? '${player1['nickName'] ?? player1['name']} 승리'
                                    : isPlayer2Win
                                    ? '${player2['nickName'] ?? player2['name']} 승리'
                                    : '무승부',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isPlayer1Win || isPlayer2Win
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // VS 대결 구조
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 선수 정보 컨테이너
                            Column(
                              children: [
                                // 1번 선수
                                _buildPlayerScoreCard(
                                  context: context,
                                  player: player1,
                                  score: item.value['score1'],
                                  isMyPlayer: myIndex == 1,
                                  isWinner: isPlayer1Win,
                                  finalScore: finalScore,
                                  playerIndex: 1,
                                  tableId: item.value['tableId'],
                                  isTop: true,
                                ),

                                SizedBox(height: 10.h),

                                // 2번 선수
                                _buildPlayerScoreCard(
                                  context: context,
                                  player: player2,
                                  score: item.value['score2'],
                                  isMyPlayer: myIndex == 2,
                                  isWinner: isPlayer2Win,
                                  finalScore: finalScore,
                                  playerIndex: 2,
                                  tableId: item.value['tableId'],
                                  isTop: false,
                                ),
                              ],
                            ),

                            // VS 표시
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'VS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 게임 종료 버튼
        if (uid == widget.scheduleProvider.schedule!['uid'] && isProgress)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: isEnd
                    ? () {
                  HapticFeedback.mediumImpact();
                  DialogManager.showBasicDialog(title: '이대로 게임을 끝낼까요?', content: '끝내면 수정은 어렵고 기록만 남아요!', confirmText: '게임종료!', onConfirm: ()=> widget.scheduleProvider.endGame(), cancelText: '앗! 잠시만요');
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnd
                      ? theme.colorScheme.secondary
                      : theme.hintColor.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  elevation: isEnd ? 4 : 0,
                  shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: theme.disabledColor.withValues(alpha: 0.1),
                  disabledForegroundColor: theme.disabledColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEnd
                          ? Icons.sports_score_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEnd ? '게임 종료하기' : '게임 진행 중',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isEnd ? Colors.white : theme.disabledColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 선수 카드 위젯
  Widget _buildPlayerScoreCard({
    required BuildContext context,
    required Map player,
    required int score,
    required bool isMyPlayer,
    required bool isWinner,
    required int finalScore,
    required int playerIndex,
    required int tableId,
    required bool isTop,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isMyPlayer
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.cardColor,
        border: Border.all(
          color: isWinner
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: isMyPlayer ? 0.2 : 0.5),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 선수 정보
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Row(
                  children: [
                    // 선수 번호
                    Container(
                      height: 30.r,
                      width: 30.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isWinner
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary.withValues(alpha: 0.7),
                        boxShadow: [
                          BoxShadow(
                            color: (isWinner
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3.r),
                      alignment: Alignment.center,
                      child: Text(
                        '${player['memberIndex']}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    SizedBox(width: 10.w),

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
                              color: isWinner
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          if (player['teamName'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                player['teamName'],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.hintColor,
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 점수 표시 및 입력
            InkWell(
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              onTap: () async {
                if(!widget.scheduleProvider.scheduleMembers!.containsKey(FirebaseAuth.instance.currentUser!.uid)) return; //만약 사용자가 참가자가아니라면 점수입력 금지
                HapticFeedback.mediumImpact();
                final newScore = await GameManager.scoreInput(finalScore, score);

                if (newScore != null && newScore != score) {
                  widget.scheduleProvider.updateScore(tableId, newScore, playerIndex);
                }
              },
              child: Container(
                width: 50.w,
                decoration: BoxDecoration(
                  color: isWinner
                      ? theme.colorScheme.primary
                      : isMyPlayer
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    topLeft: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isWinner
                        ? Colors.white
                        : isMyPlayer
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}