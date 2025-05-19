import 'package:flutter/cupertino.dart';
import '../manager/project/Import_Manager.dart';

class NadalAppbar extends StatelessWidget implements PreferredSizeWidget {
  const NadalAppbar({super.key, this.title, this.onLeading, this.actions, this.centerTitle = true, this.backgroundColor});
  final bool centerTitle;
  final String? title;
  final VoidCallback? onLeading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: AppRoute.context!.canPop() || onLeading != null ?
      IconButton(onPressed: onLeading ?? () => context.pop(),
          icon: Icon(CupertinoIcons.back, size: 22.r, color: Theme
              .of(context)
              .colorScheme.onSurface)) :  null,
      title: title != null ? ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 180.w
        ),
        child: Text(title!, style: Theme
            .of(context)
            .textTheme
            .titleLarge, overflow: TextOverflow.ellipsis,),
      ) : null,
      actions: actions,
      backgroundColor: backgroundColor ?? Theme
          .of(context)
          .scaffoldBackgroundColor,
      actionsPadding: EdgeInsets.only(right: 12.w),
      actionsIconTheme: IconThemeData(
        size: 24.r,
      ),
      elevation: 1,
      centerTitle: centerTitle,
    );
  }
}
