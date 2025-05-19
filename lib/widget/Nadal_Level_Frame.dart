import '../manager/project/Import_Manager.dart';

class NadalLevelFrame extends StatelessWidget {
  const NadalLevelFrame({super.key, this.size, required this.level});
  final double? size;
  final num? level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('LV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: (size ?? 30.r)/2.5, height: 1, color: Theme.of(context).hintColor),),
        SizedBox(width: 8.w),
        Stack(
          children: [
            Container(
              height: (size ?? 30.r), width: (size ?? 30.r),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ),
              child: Text((level ?? 1.0).toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: (size ?? 30.r)/2.5, height: 1, color: Theme.of(context).colorScheme.secondary),),
            ),
            Positioned(
                top: 0, left: 0, right: 0, bottom: 0,
                child: CircularProgressIndicator(
                  value: (level ?? 1.0)/10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  strokeWidth: 5,
                  color: Theme.of(context).colorScheme.primary,
                ))
          ],
        ),
      ],
    );
  }
}
