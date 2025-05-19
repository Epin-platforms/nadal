import '../../project/Import_Manager.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key,  this.content});
  final String? content;

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFD64545);
    const borderColor = Color(0xFFECECEC);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 내용 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: errorColor, size: 30),
                const SizedBox(height: 12),
                Text(
                  '앗! 이런...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  content ?? "알수 없는 오류가 발생했습니다",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: borderColor),

          // 버튼 영역
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: errorColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          )
        ],
      ),
    );
  }
}
