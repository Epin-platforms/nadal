import '../../../../../manager/project/Import_Manager.dart';
import '../../../../../model/room/Room_Log.dart';

// 1. 애니메이션 로그 프레임 (시스템 메시지)
class LogFrame extends StatelessWidget {
  const LogFrame({super.key, required this.roomLog});
  final RoomLog roomLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSystemLog = roomLog.uid == null;

    // 로그 메시지 생성
    final logMessage = isSystemLog
        ? roomLog.action
        : '${roomLog.name ?? '(알수없음)'} ${roomLog.action}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutQuad,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            ),
            child: Text(
              logMessage,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight: isSystemLog ? FontWeight.normal : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}