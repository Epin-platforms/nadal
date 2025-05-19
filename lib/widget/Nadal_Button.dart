import '../manager/project/Import_Manager.dart';

class NadalButton extends StatelessWidget {
  const NadalButton({super.key, this.title = "확인", this.onPressed, required this.isActive, this.height, this.color, this.margin});
  final String title;
  final bool isActive;
  final VoidCallback? onPressed;
  final double? height;
  final Color? color;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.fromLTRB(16.w, 0, 16.w, Platform.isIOS ? 0 : 15.h),
      child: InkWell(
        onTap: onPressed,
        child: AnimatedContainer(
          height: height ?? 48.h,
          decoration: isActive ? BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            color: color ?? Theme.of(context).colorScheme.primary
          ) : BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            color: Theme.of(context).highlightColor
          ),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 300),
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).hintColor),),
        ),
      ),
    );
  }
}
