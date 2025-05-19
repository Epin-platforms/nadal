import '../manager/project/Import_Manager.dart';

class TypingIndicator extends StatefulWidget {
  final String userName;

  const TypingIndicator({
    super.key,
    required this.userName,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Interval(index * 0.2, 0.5 + index * 0.2, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 프로필 이미지 자리
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
              ),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 14,
            ),
          ),

          // 이름과 타이핑 표시
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    AnimatedBuilder(
                      animation: _dotAnimations[i],
                      builder: (context, child) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          transform: Matrix4.translationValues(
                            0,
                            -3 * _dotAnimations[i].value * (1 - _dotAnimations[i].value),
                            0,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}