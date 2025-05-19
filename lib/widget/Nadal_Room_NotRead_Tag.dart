import '../manager/project/Import_Manager.dart';

class NadalRoomNotReadTag extends StatelessWidget {
  const NadalRoomNotReadTag({super.key, required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20.r, width: 20.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary
      ),
      alignment: Alignment.center,
      child: Text('$number', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Color(0xffffffff))),
    );
  }
}
