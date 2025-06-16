import '../../../../manager/project/Import_Manager.dart';

class GameState1 extends StatefulWidget {
  const GameState1({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  State<GameState1> createState() => _GameState1State();
}

class _GameState1State extends State<GameState1> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = widget.scheduleProvider.isOwner;
    final members = widget.scheduleProvider.scheduleMembers?.values.toList() ?? [];
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // 전체 스크롤 가능한 콘텐츠
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 상단 그라데이션 배경 (스크롤과 함께 이동)
                  _buildHeaderBackground(context, colorScheme),

                  SizedBox(height: 24.h),

                  // 게임 상태 카드
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _buildStatusCard(context, members),
                  ),

                  SizedBox(height: 24.h),

                  // 참가자 카드 (스크롤 가능하게 확장)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _buildMembersCard(context, members),
                  ),

                  // 하단 여백 (버튼 영역을 위한 공간)
                  SizedBox(height: isOwner && widget.scheduleProvider.currentState.index == 1 ? 100.h : 24.h),
                ],
              ),
            ),
          ),
        ],
      ),

      // 하단 버튼 영역 (고정) - FloatingActionButton 대신 bottomNavigationBar 사용
      bottomNavigationBar: isOwner && widget.scheduleProvider.currentState.index == 1
          ? Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildActionButtons(context),
        ),
      )
          : null,
    );
  }

  Widget _buildHeaderBackground(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
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
            // 타이틀
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scheduleProvider.schedule?['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '모든 참가자가 모였습니다',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            color: theme.shadowColor.withValues(alpha: 0.1),
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
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 28.r,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 16.w),
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
                    SizedBox(height: 4.h),
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
          SizedBox(height: 24.h),
          _buildInfoRow(
            context: context,
            icon: Icons.people_alt_rounded,
            label: '참가 인원',
            value: '${members.length}명',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context: context,
            icon: Icons.timer_rounded,
            label: '예상 소요 시간',
            value: widget.scheduleProvider.calculateEstimatedTime(
              members: members.cast<Map<String, dynamic>>(),
              isSingles: widget.scheduleProvider.schedule!['isSingle'] == 1,
              courts: 2,
            ),
          ),
        ],
      ),
    );
  }

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
            color: theme.shadowColor.withValues(alpha: 0.1),
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
          SizedBox(height: 16.h),

          // 참가자 목록을 스크롤 없이 전체 표시
          ...List.generate(members.length, (index) {
            final member = members[index];
            return Column(
              children: [
                ListTile(
                  onTap: ()=> context.push('/user/${member['uid']}'),
                  contentPadding: EdgeInsets.zero,
                  leading: NadalProfileFrame(
                    imageUrl: member['profileImage'],
                    size: 44.r,
                  ),
                  title: Text(
                    member['name'] ?? member['nickName'] ?? '알수없음',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    member['roomName'] ?? '소속 없음',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      member['approval'] == 1 ? '준비 완료' : '참가 불가',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: member['approval'] == 1 ? colorScheme.primary : colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < members.length - 1)
                  Divider(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

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
          size: 20.r,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        SizedBox(width: 8.w),
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

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPrimaryButton(
            context: context,
            label: '순서 추첨하기',
            icon: Icons.sports_tennis,
            onPressed: () => _showStartGameDialog(),
          ),
          SizedBox(height: 12.h),
          _buildSecondaryButton(
            context: context,
            label: '모집 다시 시작',
            icon: Icons.refresh_rounded,
            onPressed: () => widget.scheduleProvider.changeGameState(0),
          ),
        ],
      ),
    );
  }

  void _showStartGameDialog() {
    DialogManager.showBasicDialog(
      title: '추첨을 진행하시겠어요?',
      content: '추첨이 끝나면 새로운 참가자는 못 받아요!',
      confirmText: '네, 확정해주세요!',
      cancelText: '조금만 더 고민할게요',
      onConfirm: () => widget.scheduleProvider.startGame(),
    );
  }

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
      height: 56.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      height: 56.h,
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
            Icon(icon, size: 20.r),
            SizedBox(width: 8.w),
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

  WavePainter({required this.color});

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
        size.height * 0.6,
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
        size.height * 0.3,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}