import '../manager/project/Import_Manager.dart';

class AnimatedBubble extends StatefulWidget {
  final Widget child;
  final bool isSender;
  final Duration duration;
  final Curve curve;
  final bool animation;

  const AnimatedBubble({
    super.key,
    required this.child,
    required this.isSender,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.elasticOut, required this.animation,
  });

  @override
  State<AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<double>(
      begin: widget.isSender ? 0.2 : -0.2,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // ✅ 한 번만 실행
    if(widget.animation){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
      });
    }else{
      _controller.value = 1.0; // 애
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            MediaQuery.of(context).size.width * _slideAnimation.value,
            0,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: Opacity(
              opacity: _scaleAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
