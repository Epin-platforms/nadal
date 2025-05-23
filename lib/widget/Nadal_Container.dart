
import '../manager/project/Import_Manager.dart';

class NadalSolidContainer extends StatelessWidget {
  const NadalSolidContainer({
    super.key,
    this.child,
    this.height,
    this.alignment = Alignment.center,
    this.margin,
    this.padding,
    this.onTap,
    this.color,
    this.fitted = false
  });

  final VoidCallback? onTap;
  final Widget? child;
  final double? height;
  final bool fitted;
  final Alignment alignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: fitted ? null : height ?? 48.h,
        padding: padding,
        margin: margin,
        alignment: alignment,
        decoration: BoxDecoration(
          border: Border.all(
              color: color ?? Theme.of(context).highlightColor,
              width: 1.4
          ),
          borderRadius: BorderRadius.circular(8.r)
        ),
        child: child,
      ),
    );
  }
}
