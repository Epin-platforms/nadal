import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/cupertino.dart';

import '../../project/Import_Manager.dart';

class BasicDialog extends StatelessWidget {
  const BasicDialog({super.key, required this.title, required this.content, required this.confirmText, this.onConfirm, this.cancelText, this.onCancel, this.icon, this.backgroundColor});
  final String title;
  final String content;
  final String confirmText;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final Widget? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
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
                if(icon != null)
                Padding(padding: EdgeInsets.only(bottom: 8), child: icon)
                else
                Padding(padding: EdgeInsets.only(bottom: 8), child: Icon(Icons.info_outline_rounded, size: 30, color: Theme.of(context).colorScheme.primary)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1),

          // 버튼 영역
          if (cancelText != null)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    child: Text(cancelText!),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF3CB8C5),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    child: Text(confirmText),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF3CB8C5),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
            )
        ],
      ),
    );
  }
}
