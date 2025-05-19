import '../../../manager/project/Import_Manager.dart';

class BounceWidget extends StatefulWidget {
  const BounceWidget({super.key, required this.child, this.amplitude = 10, this.duration});
  final Widget child;
  final double amplitude; // default: 10
  final Duration? duration; // default: 1200ms
  @override
  State<BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<BounceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: widget.amplitude/2, end: -(widget.amplitude/2)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: child
        );
      },
      child: widget.child,
    );
  }
}
