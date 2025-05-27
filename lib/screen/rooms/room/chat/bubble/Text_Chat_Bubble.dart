import '../../../../../animation/Animate_Bubble.dart';
import '../../../../../manager/project/Import_Manager.dart';

class TextChatBubble extends StatelessWidget {
  const TextChatBubble({
    super.key,
    required this.text,
    required this.isSender,
    required this.tail, required this.animation,
  });

  final bool animation;
  final String text;
  final bool isSender;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 깔끔한 말풍선 색상 설정
    final backgroundColor = isSender
        ? colorScheme.primary // 발신자 메시지는 메인 컬러 사용
        : (isDark
        ? const Color(0xFF2A2A36) // 다크 모드에서 수신자 메시지는 어두운 회색
        : const Color(0xFFF2F2F7)); // 라이트 모드에서 수신자 메시지는 밝은 회색

    // 텍스트 색상 - 좋은 대비를 위해 색상 조정
    final textColor = isSender
        ? theme.colorScheme.onPrimary // 발신자 메시지는 흰색 텍스트
        : (isDark
        ? Colors.white.withValues(alpha: 0.9) // 다크 모드에서 수신자 메시지는 밝은 텍스트
        : const Color(0xFF1F1F1F)); // 라이트 모드에서 수신자 메시지는 거의 검은색 텍스트

    // 말풍선 모양 설정 (꼬리 유무에 따라)
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isSender || !tail ? 18 : 4),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(isSender && tail ? 4 : 18),
    );

    return AnimatedBubble(
      isSender: isSender,
      duration: const Duration(milliseconds: 350),
      animation: animation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 210.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 15.sp, // 조금 더 큰 글자 크기
            height: 1.4, // 줄 간격을 적당히 조정
            fontWeight: FontWeight.w400, // 일반 텍스트 무게로 변경
            letterSpacing: -0.2, // 글자 간격 약간 줄임 (한글에 적합)
          ),
        ),
      ),
    );
  }
}