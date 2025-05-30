

import '../../../../../manager/project/Import_Manager.dart';

class MyLevel extends StatelessWidget {
  const MyLevel({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final me = scheduleProvider.scheduleMembers![uid];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('게임 요약', style: theme.textTheme.titleMedium,),
            SizedBox(height: 12,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    return Container(
                      width: 100.r,
                      height: 100.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${me?['ranking'] ?? '?'}위', style: theme.textTheme.labelLarge?.copyWith(fontSize: 22.sp, color: theme.colorScheme.secondary, fontWeight: FontWeight.w800),),
                          SizedBox(height: 8.h,),
                          Text('등수', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),)
                        ],
                      ),
                    );
                  }
                ),

                Builder(
                    builder: (context) {
                      final games = scheduleProvider.getMyGames();
                      final winCount = games.where(
                              (e) =>
                          ((e.value['player1_0'] == uid || e.value['player1_1'] == uid) && e.value['score1'] > e.value['score2']) ||
                              ((e.value['player2_0'] == uid || e.value['player2_1'] == uid) && e.value['score2'] > e.value['score1'])
                      ).length;
                      final winRatio = games.isEmpty ? 0.0 : winCount / games.length;
                      return Container(
                        width: 100.r,
                        height: 100.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(child: Text('${(winRatio * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelLarge?.copyWith(fontSize: 22.sp, color: theme.colorScheme.secondary, fontWeight: FontWeight.w800),)),
                            SizedBox(height: 8.h,),
                            Text('승률', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),)
                          ],
                        ),
                      );
                    }
                ),


                Builder(
                    builder: (context) {
                      final origin = (scheduleProvider.gameResult!.first['original'] as num).toDouble();
                      final fluctuationSum = scheduleProvider.gameResult!
                          .map((e) => (e['fluctuation'] as num).toDouble())
                          .fold(origin, (prev, element) => prev + element);

                      final double levelDiff = fluctuationSum - origin;
                      return Container(
                        width: 100.r,
                        height: 100.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(child: Text('${levelDiff > 0 ? '+':''}${(levelDiff * 100).toStringAsFixed(1)}%', style: theme.textTheme.labelLarge?.copyWith(fontSize: 22.sp, color: theme.colorScheme.secondary, fontWeight: FontWeight.w800),)),
                            SizedBox(height: 8.h,),
                            Text('레벨변화', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),)
                          ],
                        ),
                      );
                    }
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
