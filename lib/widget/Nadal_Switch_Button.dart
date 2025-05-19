import '../manager/project/Import_Manager.dart';

class NadalSwitchButton extends StatelessWidget {
  const NadalSwitchButton({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = const Color(0xFF00C4B4); // 메인 민트색
    final Color trackColor = isDark ? Colors.grey[700]! : Colors.grey[350]!;
    return SizedBox(
      height: 38.h,
      child: FittedBox(
        child: Switch(
          value: value,
          onChanged: onChanged,
          padding: EdgeInsets.zero,
          thumbIcon: WidgetStatePropertyAll(Icon(value ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded, color: value ? activeColor : trackColor)),
          activeColor: Colors.white,      // 썸네일(공) 색
          activeTrackColor: activeColor,  // 트랙 색 (on)
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: trackColor, // 트랙 색 (off)
          trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
