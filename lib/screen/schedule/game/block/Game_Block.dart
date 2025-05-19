import '../../../../manager/project/Import_Manager.dart';

class GameBlock extends StatelessWidget {
  const GameBlock({super.key, required this.mainText, required this.subText});
  final String mainText;
  final String subText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: Image.asset('assets/image/icon/lock_page.png', height: 180, width: 180,)),
        SizedBox(height: 16,),
        Column(
          children: [
            Text(mainText, style: theme.textTheme.titleLarge,),
            Text(subText, style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor))
          ],
        ),
        const SizedBox(height: 120,)
      ],
    );
  }
}
