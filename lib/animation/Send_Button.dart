import 'package:flutter/cupertino.dart';

import '../manager/project/Import_Manager.dart';

class SendButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      customBorder: CircleBorder(),
      onTap: onPressed,
      child: Container(
        width: 46.r,
        height: 46.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
            BootstrapIcons.send_fill,
            color: isEnabled
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            size: 20.r
        ),
      ),
    );
  }
}