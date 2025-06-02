import '../manager/project/Import_Manager.dart';

class NadalRoomNotReadTag extends StatelessWidget {
  const NadalRoomNotReadTag({super.key, required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23.r, width: 23.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(2),
      child: FittedBox(child: Text('$number', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Color(0xffffffff)))),
    );
  }
}
