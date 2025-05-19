import '../manager/project/Import_Manager.dart';

class ExpandableComment extends StatefulWidget {
  const ExpandableComment({super.key, required this.text, this.maxHeight = 70});
  final String text;
  final double maxHeight;
  @override
  State<ExpandableComment> createState() => _ExpandableCommentState();
}

class _ExpandableCommentState extends State<ExpandableComment> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _overflow = false;

  @override
  void initState() {
    super.initState();
    // 초기 overflow 계산
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    final span = TextSpan(text: widget.text, style: Theme.of(context).textTheme.labelMedium);
    final tp = TextPainter(
      text: span,
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width);

    if (tp.size.height > widget.maxHeight) {
      setState(() {
        _overflow = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      style: Theme.of(context).textTheme.labelMedium,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: ConstrainedBox(
            constraints: _expanded
                ? const BoxConstraints()
                : BoxConstraints(maxHeight: widget.maxHeight),
            child: textWidget,
          ),
        ),
        if (_overflow)
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                _expanded ? '접기' : '...더보기',
                style: TextStyle(
                  fontSize: 13,
                  color: _expanded ? Theme.of(context).hintColor : Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
