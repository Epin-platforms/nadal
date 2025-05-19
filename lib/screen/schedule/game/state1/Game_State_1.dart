import 'package:my_sports_calendar/provider/game/Game_Provider.dart';
import '../../../../manager/project/Import_Manager.dart';

class GameState1 extends StatefulWidget {
  const GameState1({super.key, required this.gameProvider, required this.scheduleProvider});
  final GameProvider gameProvider;
  final ScheduleProvider scheduleProvider;

  @override
  State<GameState1> createState() => _GameState1State();
}

class _GameState1State extends State<GameState1> {

  // 게임 예상 소요 시간 계산 함수 (단식/복식 대응)
  String calculateEstimatedTime({
    required List members,
    required bool isSingles, // 단식 여부 (true: 단식, false: 복식)
    int courts = 2, // 기본 코트 수
  }) {
    // 총 게임 수 계산
    int totalMatches = 0;
    int playerCount = members.length;

    if (isSingles) {
      // 단식 게임: n*(n-1)/2 공식으로 계산 (모든 선수가 다른 모든 선수와 한 번씩 대결)
      totalMatches = (playerCount * (playerCount - 1)) ~/ 2;
    } else {
      // 복식 게임: 인원 수에 따른 총 게임 수 결정
      // 복식 대진표에 정의된 게임 수 매핑
      switch (playerCount) {
        case 5: totalMatches = 5; break;
        case 6: totalMatches = 6; break;
        case 7: totalMatches = 7; break;
        case 8: totalMatches = 8; break;
        case 9: totalMatches = 9; break;
        case 10: totalMatches = 10; break;
        case 11: totalMatches = 11; break;
        case 12: totalMatches = 12; break;
        case 13: totalMatches = 13; break;
        case 14: totalMatches = 14; break;
        case 15: totalMatches = 15; break;
        case 16: totalMatches = 16; break;
        default:
        // 정확한 값이 없는 경우 평균적인 값으로 추정
        // 일반적으로 n명의 경우 약 n 또는 n+1 정도의 게임이 생성됨
          totalMatches = playerCount;
      }
    }

    // 게임당 예상 소요 시간 (평균)
    // 단식은 복식보다 일반적으로 시간이 덜 소요됨
    double minTimePerMatch = isSingles ? 0.75 : 1.0; // 단식: 45분, 복식: 1시간 최소
    double maxTimePerMatch = isSingles ? 1.25 : 1.5; // 단식: 1시간 15분, 복식: 1.5시간 최대

    // 총 소요 시간 계산 (코트 수 고려)
    double minTotalHours = (totalMatches * minTimePerMatch) / courts;
    double maxTotalHours = (totalMatches * maxTimePerMatch) / courts;

    // 최소 시간은 반올림하여 0.5 단위로 표시, 최대 시간은 올림하여 정수로 표시
    double roundedMinHours = (minTotalHours * 2).round() / 2; // 0.5 단위로 반올림
    int ceilingMaxHours = maxTotalHours.ceil(); // 올림하여 정수로

    // 시간이 너무 짧은 경우 (30분 미만) 최소 0.5시간으로 설정
    if (roundedMinHours < 0.5) roundedMinHours = 0.5;

    // 시간 범위가 같으면 단일 값으로 표시
    if (roundedMinHours == ceilingMaxHours.toDouble()) {
      return '약 ${roundedMinHours.toStringAsFixed(roundedMinHours.truncateToDouble() == roundedMinHours ? 0 : 1)}시간';
    }

    // 최소값과 최대값이 다르면 범위로 표시
    return '약 ${roundedMinHours.toStringAsFixed(roundedMinHours.truncateToDouble() == roundedMinHours ? 0 : 1)}~${ceilingMaxHours}시간';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = widget.gameProvider.scheduleProvider.schedule!["uid"] == FirebaseAuth.instance.currentUser!.uid;
    final members = widget.scheduleProvider.scheduleMembers!.entries.map((e) => e.value).toList();

    // 테마에서 컬러 가져오기
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // 상단 물결 모양 배경
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.tertiary,
                    colorScheme.primary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // 배경 패턴
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WavePainter(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // 앱 타이틀
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 24,
                    child: Text(
                      widget.gameProvider.scheduleProvider.schedule!['title'],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 메인 콘텐츠
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70), // 상단 공간

                // 게임 상태 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStatusCard(context, members),
                ),

                // 참가자 카드
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildMembersCard(context, members),
                  ),
                ),

                // 하단 버튼 영역
                if (isOwner && widget.gameProvider.scheduleProvider.schedule!['state'] == 1)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    child: Column(
                      children: [
                        _buildPrimaryButton(
                          context: context,
                          label: '순서 추첨하기',
                          icon: Icons.sports_tennis,
                          onPressed: (){
                            DialogManager.showBasicDialog(title: '추첨을 진행하시겠어요?', content: '추첨이 끝나면 새로운 참가자는 못 받아요!',
                                confirmText: '네, 확정해주세요!', cancelText: '조금만 더 고민할게요', onConfirm: ()=>widget.gameProvider.startGame());
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSecondaryButton(
                          context: context,
                          label: '모집 다시 시작',
                          icon: Icons.refresh_rounded,
                          onPressed: () => widget.gameProvider.changeState(0),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 상태 카드 위젯 (현재 게임 상태 표시)
  Widget _buildStatusCard(BuildContext context, List members) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '게임 준비 완료',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '모든 참가자가 모였습니다',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            context: context,
            icon: Icons.people_alt_rounded,
            label: '참가 인원',
            value: '${members.length}명',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context: context,
            icon: Icons.timer_rounded,
            label: '예상 소요 시간',
            value: calculateEstimatedTime(
              members: members,
              isSingles: widget.gameProvider.scheduleProvider.schedule!['isSingle']  ==1, // 복식 게임
              courts: 2,  // 코트 수
            ),
          ),
        ],
      ),
    );
  }

  // 참가자 카드 위젯
  Widget _buildMembersCard(BuildContext context, List members) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참가자 목록',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: members.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final member = members[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: NadalProfileFrame(imageUrl: member['profileImage'],),
                  title: Text(
                      member['name'] ?? member['nickName'] ?? '알수없음',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    member['gender'] == null ? '익명 진행' : '${member['birthYear']}/${member['gender']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '준비 완료',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 정보 행 위젯 (아이콘 + 레이블 + 값)
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }



  // 주요 액션 버튼 위젯
  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 보조 액션 버튼 위젯
  Widget _buildSecondaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 물결 패턴 페인터
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();

    // 첫 번째 물결
    path.moveTo(0, size.height * 0.6);

    for (int i = 0; i < size.width.toInt(); i += 40) {
      path.cubicTo(
          i + 10,
          size.height * 0.5,
          i + 30,
          size.height * 0.7,
          i + 40,
          size.height * 0.6
      );
    }

    // 두 번째 물결
    path.moveTo(0, size.height * 0.3);

    for (int i = 0; i < size.width.toInt(); i += 60) {
      path.cubicTo(
          i + 15,
          size.height * 0.2,
          i + 45,
          size.height * 0.4,
          i + 60,
          size.height * 0.3
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}