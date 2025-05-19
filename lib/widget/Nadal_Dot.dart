import '../manager/project/Import_Manager.dart';

class NadalDot extends StatelessWidget {
  const NadalDot({super.key, this.size, this.color});
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size ?? 4.r),
      child: Container(
        height: size ?? 4.r,
        width: size ?? 4.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Theme.of(context).colorScheme.primary
        ),
      ),
    );
  }
}
