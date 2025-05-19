import '../manager/project/Import_Manager.dart';

class NadalVerification extends StatelessWidget {
  const NadalVerification({super.key, this.size, required this.isConnected});
  final double? size;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? ThemeManager.successColor : ThemeManager.errorColor;
    final icon = isConnected ? BootstrapIcons.person_check_fill : BootstrapIcons.person_fill_slash;
    return Container(
      height: (size ?? 35.r),
      width: (size ?? 35.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3)
      ),
      padding: EdgeInsets.all((size ?? 35.r)/4.3),
      child: FittedBox(
        child: Icon(icon, color: color,),
      ),
    );
  }
}
