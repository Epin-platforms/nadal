import '../../../../../manager/project/Import_Manager.dart';

class WalkOverCard extends StatelessWidget {
  const WalkOverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.airline_stops, size: 24, color: theme.hintColor,),
          SizedBox(width: 4,),
          Text('부전승', style: TextStyle(fontSize: 11, color: theme.hintColor),)
        ],
      ),
    );
  }
}
