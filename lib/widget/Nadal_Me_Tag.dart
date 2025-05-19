import '../manager/project/Import_Manager.dart';

class NadalMeTag extends StatelessWidget {
  const NadalMeTag({super.key, this.size});
  final double? size;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SoftEdgeClipper(),
      child: Container(
        height: size ?? 15.r,
        width: size ?? 15.r,
        color: Theme.of(context).colorScheme.secondary,
        alignment: Alignment.center,
        child: FittedBox(child: Text('나', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSecondary),)),
      ),
    );
  }
}
