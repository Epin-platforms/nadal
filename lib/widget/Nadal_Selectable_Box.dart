import '../manager/project/Import_Manager.dart';

class NadalSelectableBox extends StatelessWidget {
  const NadalSelectableBox({super.key, required this.selected, this.height = 48, this.surFix, this.preFix, required this.text});
  final bool selected;
  final double height;
  final String text;
  final Widget? surFix;
  final Widget? preFix;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        height: height,
        duration: const Duration(milliseconds: 300),
        decoration: selected ?
        BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.primary
        ) : BoxDecoration (
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).highlightColor, width: 1.3),
            color: Theme.of(context).highlightColor.withValues(alpha: 0.2)
        ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: height/4),
      child: Row(
        mainAxisAlignment: surFix == null && preFix == null ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if(preFix != null)
            preFix!,
          Text(text, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).hintColor, fontWeight: selected ? FontWeight.w800 : FontWeight.w400),),
          if(surFix != null)
            surFix!
        ],
      ),
    );
  }
}
