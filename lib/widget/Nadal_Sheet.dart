import 'package:flutter/cupertino.dart';

import '../manager/project/Import_Manager.dart';


class NadalSheet extends StatelessWidget {
  const NadalSheet({super.key, this.title, this.message, required this.actions});
  final String? title;
  final String? message;
  final List<CupertinoActionSheetAction> actions;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoActionSheet(
      title: title != null ? Text(title!, style: theme.textTheme.titleMedium,): null,
      message: message != null ? Text(message!, style: theme.textTheme.labelLarge,) : null,
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context, null),
        isDefaultAction: true,
        child: Text('취소', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error) ),
      ),
    );
  }
}
