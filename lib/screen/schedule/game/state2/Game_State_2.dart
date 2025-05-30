import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Reorder_List.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/touranment/Tournament_Team_Reorder_List.dart';
import '../../../../manager/project/Import_Manager.dart';
import 'kdk/Nadal_KDK_Reorder_List.dart';

class GameState2 extends StatefulWidget {
  const GameState2({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  State<GameState2> createState() => _GameState2State();
}

class _GameState2State extends State<GameState2> {
  @override
  Widget build(BuildContext context) {
    // 안전성을 위한 null 체크
    if (widget.scheduleProvider.schedule == null) {
      return const Center(
        child: Text('게임 정보를 불러올 수 없습니다.'),
      );
    }

    final gameType = widget.scheduleProvider.gameType;
    if (gameType == null) {
      return const Center(
        child: Text('올바르지 않은 게임 타입입니다.'),
      );
    }

    // 인덱스가 배정되었는지 확인 (Provider로 자동 감지)
    final hasIndexes = _checkMemberIndexes();

    if (!hasIndexes) {
      return _buildIndexLoadingView(context);
    }

    // 게임 타입에 따른 위젯 반환
    switch (gameType) {
      case GameType.kdkSingle:
      case GameType.kdkDouble:
        return NadalKDKReorderList(
          scheduleProvider: widget.scheduleProvider,
        );

      case GameType.tourSingle:
        return TournamentReorderList(
          scheduleProvider: widget.scheduleProvider,
        );

      case GameType.tourDouble:
        return TournamentTeamReorderList(
          scheduleProvider: widget.scheduleProvider,
        );
    }
  }

  /// 멤버들에게 인덱스가 배정되었는지 확인
  bool _checkMemberIndexes() {
    final allMembers = widget.scheduleProvider.getAllMembers();

    if (allMembers.isEmpty) return false;

    // 모든 멤버가 memberIndex를 가지고 있는지 확인
    return allMembers.values.every((member) =>
    member['memberIndex'] != null && member['memberIndex'] > 0
    );
  }

  /// 인덱스 로딩 중 화면
  Widget _buildIndexLoadingView(BuildContext context) {
    final theme = Theme.of(context);
    final gameType = widget.scheduleProvider.gameType;
    final realCount = widget.scheduleProvider.realMemberCount;
    final totalSlots = widget.scheduleProvider.totalSlots;
    final walkOverCount = widget.scheduleProvider.walkOverCount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48.r,
                          height: 48.r,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shuffle_rounded,
                            color: Colors.white,
                            size: 24.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '순서 추첨 중...',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '잠시만 기다려주세요',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // 로딩 애니메이션
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 40.r,
                  height: 40.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              '참가자 순서를 배정하고 있어요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              '곧 완료됩니다',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),

            SizedBox(height: 40.h),

            // 게임 정보 카드
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 24.r,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '게임 정보',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  _buildInfoRow(
                    context,
                    '게임 타입',
                    _getGameTypeText(gameType),
                  ),

                  SizedBox(height: 8.h),

                  _buildInfoRow(
                    context,
                    '실제 참가자',
                    '$realCount명',
                  ),

                  if (gameType == GameType.tourSingle || gameType == GameType.tourDouble) ...[
                    SizedBox(height: 8.h),
                    _buildInfoRow(
                      context,
                      '토너먼트 규모',
                      '$totalSlots${gameType == GameType.tourDouble ? '팀' : '명'}',
                    ),

                    if (walkOverCount > 0) ...[
                      SizedBox(height: 8.h),
                      _buildInfoRow(
                        context,
                        '부전승 추가',
                        '$walkOverCount${gameType == GameType.tourDouble ? '팀' : '명'}',
                        valueColor: theme.colorScheme.secondary,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const Spacer(),

            // 하단 설명
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 20.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        gameType == GameType.tourSingle || gameType == GameType.tourDouble
                            ? '토너먼트는 2의 배수로 진행되어 부족한 자리는 부전승으로 채워집니다.'
                            : 'KDK 게임은 모든 참가자가 공정하게 대결할 수 있도록 순서를 배정합니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(
      BuildContext context,
      String label,
      String value,
      {Color? valueColor}
      ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 게임 타입 텍스트 반환
  String _getGameTypeText(GameType? gameType) {
    if(gameType == null){
      return '알수없음';
    }

    switch (gameType) {
      case GameType.kdkSingle:
        return 'KDK 단식';
      case GameType.kdkDouble:
        return 'KDK 복식';
      case GameType.tourSingle:
        return '토너먼트 단식';
      case GameType.tourDouble:
        return '토너먼트 복식';
    }
  }
}