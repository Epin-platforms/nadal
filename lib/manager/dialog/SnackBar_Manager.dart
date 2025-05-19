import '../project/Import_Manager.dart';

class SnackBarManager{
  static void showCleanSnackBar(BuildContext context, String message, {IconData? icon}) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: const Duration(milliseconds: 3000),
      content: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        child: Row(
          children: [
            Icon(icon ?? BootstrapIcons.check2_circle, color: Colors.white, size: 18,),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}