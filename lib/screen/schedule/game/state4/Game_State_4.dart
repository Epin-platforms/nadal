import 'package:my_sports_calendar/screen/schedule/game/state4/widget/Kdk_Result.dart';
import 'package:my_sports_calendar/screen/schedule/game/state4/widget/My_Level.dart';
import 'package:my_sports_calendar/screen/schedule/game/state4/widget/My_Result.dart';
import '../../../../manager/project/Import_Manager.dart';

class GameState4 extends StatefulWidget {
  const GameState4({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  State<GameState4> createState() => _GameState4State();
}

class _GameState4State extends State<GameState4> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameData();
    });
  }

  Future<void> _initializeGameData() async {
    // 게임 결과가 없으면 가져오기
    if (widget.scheduleProvider.gameResult == null) {
      await widget.scheduleProvider.fetchGameResult();
    }

    // 게임 테이블이 없으면 가져오기
    if (widget.scheduleProvider.gameTables == null) {
      await widget.scheduleProvider.fetchGameTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 안전성을 위한 null 체크
    if (widget.scheduleProvider.schedule == null) {
      return const Center(
        child: Text('게임 정보를 불러올 수 없습니다.'),
      );
    }

    // 데이터 로딩 중
    if (widget.scheduleProvider.gameResult == null ||
        widget.scheduleProvider.gameTables == null) {
      return Center(
        child: widget.scheduleProvider.isLoading
            ? NadalCircular()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.r,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              '게임 데이터를 불러올 수 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => _initializeGameData(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isParticipant = currentUserId != null &&
        widget.scheduleProvider.scheduleMembers?.containsKey(currentUserId) == true;

    return SingleChildScrollView(
      child: Column(
        children: [
          // 내가 참가했다면 내 결과 표시
          if (isParticipant) ...[
            MyResult(
              scheduleProvider: widget.scheduleProvider,
            ),
            MyLevel(
              scheduleProvider: widget.scheduleProvider,
            ),
          ],
          if(!isParticipant)...[
            SizedBox(
              height: 300,
              child: NadalEmptyList(
                  title: '요약할 게임이 없어요...',
                  subtitle: '참여한 게임만 결과를 볼 수 있어요'
              ),
            )
          ],
          // KDK 게임인 경우 대진표 결과 표시
          if (widget.scheduleProvider.gameType == GameType.kdkSingle ||
              widget.scheduleProvider.gameType == GameType.kdkDouble)
            KdkResult(
              scheduleProvider: widget.scheduleProvider,
            )
          else
            SizedBox(
              height: 150.h,
              child: Center(
                child : TextButton.icon(
                    onPressed: (){
                      widget.scheduleProvider.setCurrentStateView(3);
                    }, icon: Icon(Icons.info_outline, size: 24.r,  color: Theme.of(context).colorScheme.primary,),
                    label: Text('자세히보기', style: Theme.of(context).textTheme.titleMedium,),
                )
              ),
            )
        ],
      ),
    );
  }
}