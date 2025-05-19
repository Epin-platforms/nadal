import '../manager/form/widget/Color_Form_Manager.dart';
import '../manager/project/Import_Manager.dart';

class NadalScheduleState extends StatelessWidget {
  const NadalScheduleState({super.key, required this.state, this.onDeleted,  this.elevation = 0});
  final int state;
  final VoidCallback? onDeleted;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        TextFormManager.stateToText(state) ?? '알수없음',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: elevation == 0 ? Theme.of(context).hintColor : ColorFormManager.stateColor(state))
      ),
      elevation: elevation,
      backgroundColor: elevation == 0 ?  Theme.of(context).highlightColor : ColorFormManager.stateColor(state).withValues(alpha: 0.2),
      labelPadding: EdgeInsets.zero,
      shadowColor: Theme.of(context).highlightColor,
      side: BorderSide.none,
      onDeleted: onDeleted,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      deleteIcon: Icon(Icons.expand_more, color: elevation == 0 ? Theme.of(context).hintColor : ColorFormManager.stateColor(state)),
    );
  }
}
