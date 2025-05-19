import '../manager/form/widget/Color_Form_Manager.dart';
import '../manager/project/Import_Manager.dart';

class NadalScheduleTag extends StatelessWidget {
  const NadalScheduleTag({super.key, required this.tag, this.padding, this.fontSize});
  final String tag;
  final EdgeInsets? padding;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    return  Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorFormManager.getTagColor(tag).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorFormManager.getTagColor(tag), fontSize: fontSize ?? 11.sp)
      ),
    );
  }
}
