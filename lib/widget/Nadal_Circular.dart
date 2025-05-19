import '../manager/project/Import_Manager.dart';

class NadalCircular extends StatelessWidget {
  const NadalCircular({super.key,  this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size ?? 60.r,
      width: size ?? 60.r,
      child: FittedBox(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          strokeCap: StrokeCap.round,
          strokeWidth: (size ?? 60.r)/7,
        ),
      ),
    );
  }
}
