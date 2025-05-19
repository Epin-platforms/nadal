import '../../../../../manager/project/Import_Manager.dart';

class RemovedChatBubble extends StatelessWidget {
  const RemovedChatBubble({
    super.key,
    required this.isSender,
    required this.tail,
  });

  final bool isSender;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 삭제된 메시지는 회색으로 통일
    final backgroundColor = isDark
        ? const Color(0xFF272730)
        : const Color(0xFFEBEBF0);

    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF8E8E93);

    // 말풍선 모양 설정 (꼬리 유무에 따라)
    final borderRadius = BorderRadius.only(
      topLeft:  Radius.circular(isSender || !tail ? 18 : 4),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(18),
      bottomRight: Radius.circular(isSender && tail ? 4 : 18),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 200), // 더 작은 너비
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.do_not_disturb_alt,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            '삭제된 메시지',
            style: TextStyle(
              color: textColor,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}