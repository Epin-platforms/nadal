import '../manager/project/Import_Manager.dart';

class SendButton extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  _SendButtonState createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _scaleAnimation.value + (1 - _scaleAnimation.value) * (1 - _rotateAnimation.value),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isEnabled
            ? () {
          _controller.forward();
          widget.onPressed();
        }
            : null,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isEnabled
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.send_rounded,
            color: widget.isEnabled
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            size: 20,
          ),
        ),
      ),
    );
  }
}