import '../../../manager/project/Import_Manager.dart';

class IosPopGesture extends StatelessWidget {
  const IosPopGesture({super.key, required this.child, this.onPop});
  final Widget child;
  final Future<dynamic> Function()? onPop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          final nav = Navigator.of(context);
          if (!didPop) {
            final shouldPop = await (onPop?.call() ?? Future.value(true));
            final value = await onPop?.call();
            if (shouldPop) {
              nav.pop(value);
            }
          }
        },
        child: FocusGuard(child: child),
      ),
    );
  }
}
