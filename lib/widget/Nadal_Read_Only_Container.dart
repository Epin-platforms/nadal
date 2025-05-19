import '../manager/project/Import_Manager.dart';

class NadalReadOnlyContainer extends StatelessWidget {
  const NadalReadOnlyContainer({super.key, required this.label, required this.value, this.height});
  final String label;
  final String value;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 7),
          child: Container(
            height: height ?? 48.h,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor.withValues(alpha: 0.05), // 살짝 음영
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).highlightColor,
                width: 1,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value.isNotEmpty ? value : '-',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 13,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        ),
      ],
    );
  }
}
