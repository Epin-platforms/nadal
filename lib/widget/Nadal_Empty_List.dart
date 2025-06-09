import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:hive/hive.dart';

import '../manager/project/Import_Manager.dart';


class NadalEmptyList extends StatelessWidget {
  const NadalEmptyList({super.key, required this.title, this.subtitle, this.onAction, this.actionText, this.icon});
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionText;
  final Icon? icon;


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/image/icon/empty.png", height: 72.r, width: 72.r,),
          SizedBox(height: 16.h),
          ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320.w
              ),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,)),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (actionText != null && onAction != null) ...[
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: SizedBox(
                height: 24.r, width: 24.r,
                child: FittedBox(
                  child: icon ?? Icon(BootstrapIcons.plus, color: Theme.of(context).colorScheme.onPrimary,),
                )
              ),
              label: Text(actionText!, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            )
          ]
        ],
      ),
    );
  }
}
