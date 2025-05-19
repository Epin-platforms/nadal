import '../manager/project/Import_Manager.dart';

class NadalGenderIcon extends StatelessWidget {
  const NadalGenderIcon({super.key, this.size = 35, required this.gender});
  final double size;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    final color = gender == 'M' ? Color(0xff3CB371) : gender == 'F' ? Color(0xffB084CC) : Color(0xff9E9E9E);
    final icon = gender == 'M' ? BootstrapIcons.gender_male : gender == 'F' ? BootstrapIcons.gender_female : BootstrapIcons.patch_question;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3)
      ),
      padding: EdgeInsets.all(size/4),
      child: FittedBox(child: Icon(icon, color: color,)),
    );
  }
}
