import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/screen/schedule/Schedule_Main.dart';
import 'package:my_sports_calendar/screen/schedule/game/state1/Game_State_1.dart';
import 'package:my_sports_calendar/screen/schedule/widget/Schedule_Step_Selector.dart';
import 'package:my_sports_calendar/util/handler/Deep_Link_Handler.dart';
import '../../manager/project/Import_Manager.dart';
import '../../provider/notification/Notification_Provider.dart';
import 'game/block/Game_Block.dart';
import 'game/state2/Game_State_2.dart';
import 'game/state3/Game_State_3.dart';
import 'game/state4/Game_State_4.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key, required this.scheduleId});
  final int scheduleId;

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late ScheduleProvider scheduleProvider;
  late UserProvider userProvider;
  late CommentProvider commentProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSchedule();
    });
  }

  Future<void> _initializeSchedule() async {
    try {
      // 스케줄 데이터 초기화 (게임 데이터도 포함)
      await scheduleProvider.initializeSchedule(widget.scheduleId);

      // 댓글 초기화
      commentProvider.initCommentProvider(widget.scheduleId);

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      // 에러 처리는 ScheduleProvider 내부에서 처리됨
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // ScheduleProvider의 dispose에서 게임 관련 정리도 함께 처리됨
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    scheduleProvider = Provider.of<ScheduleProvider>(context);
    userProvider = Provider.of<UserProvider>(context);
    commentProvider = Provider.of<CommentProvider>(context);
    final theme = Theme.of(context);

    // 초기화 전이거나 스케줄이 없는 경우
    if (!_isInitialized || scheduleProvider.schedule == null) {
      return Material(
        child: Center(
          child: CircularProgressIndicator()
        ),
      );
    }

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '스케줄',
          actions: [
            NadalIconButton(
              onTap: () => _showScheduleActions(theme),
              icon: BootstrapIcons.three_dots_vertical,
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 게임 스케줄인 경우 단계 선택기 표시
              if (scheduleProvider.isGameSchedule)
                ScheduleStepSelector(
                  currentStep: scheduleProvider.currentStateView,
                  onStepTap: (int index) => scheduleProvider.setCurrentStateView(index),
                  stepTitles: List.generate(5, (index) => TextFormManager.stateToText(index) ?? ''),
                  totalSteps: 5,
                  viewStep: scheduleProvider.schedule!['state'],
                ),

              // 메인 콘텐츠
              Expanded(
                child: _buildMainContent(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (!scheduleProvider.isGameSchedule) {
      // 일반 스케줄
      return ScheduleMain(
        commentProvider: commentProvider,
        provider: scheduleProvider,
        userProvider: userProvider,
      );
    }

    // 게임 스케줄
    final currentState = scheduleProvider.currentStateView;
    final actualState = scheduleProvider.schedule!['state'];

    // 현재 선택된 상태가 실제 진행 상태보다 높으면 차단
    if (currentState > actualState) {
      return GameBlock(
        mainText: '미공개 정보입니다!',
        subText: '게임 진행에따라 페이지가 오픈돼요',
      );
    }

    // 각 상태에 맞는 위젯 반환
    switch (currentState) {
      case 0:
        return ScheduleMain(
          commentProvider: commentProvider,
          provider: scheduleProvider,
          userProvider: userProvider,
        );
      case 1:
        return GameState1(
          scheduleProvider: scheduleProvider,
        );
      case 2:
        return GameState2(
          scheduleProvider: scheduleProvider,
        );
      case 3:
        return GameState3(
          scheduleProvider: scheduleProvider,
        );
      case 4:
        return GameState4(
          scheduleProvider: scheduleProvider,
        );
      default:
        return ScheduleMain(
          commentProvider: commentProvider,
          provider: scheduleProvider,
          userProvider: userProvider,
        );
    }
  }

  void _showScheduleActions(ThemeData theme) {
    final isOwner = scheduleProvider.isOwner;
    final currentState = scheduleProvider.schedule?['state'] ?? 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final nav = Navigator.of(context);

        return NadalSheet(
          actions: [
            // 공유
            CupertinoActionSheetAction(
              onPressed: () {
                nav.pop();
                shareSchedule(context, scheduleProvider.schedule!['scheduleId'], scheduleProvider.schedule!['title']);
              },
              child: Text(
                '공유',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.secondaryHeaderColor,
                ),
              ),
            ),

            // 초대
            CupertinoActionSheetAction(
              onPressed: () async {
                final notiProvider = context.read<NotificationProvider>();
                final List<String>? res = await context.push('/friends?selectable=true');

                if(res != null && res.isNotEmpty){
                  final users = scheduleProvider.filterInviteAbleUsers(res);

                  if(users.length != res.length){
                    SnackBarManager.showCleanSnackBar(context,
                        '이미 참가 중인 사용자가 있어 제외하고 전송됩니다');
                  }

                  final failed = await notiProvider.sendNotification(
                      receivers: users,
                      title: '${scheduleProvider.schedule!['title']} 일정에서 초대가 왔습니다',
                      subTitle: '지금 바로 확인해볼까요?',
                      routing: '/schedule/${scheduleProvider.schedule?['scheduleId']}'
                  );
                  SnackBarManager.showCleanSnackBar(context, '${users.length - failed.length}/${users.length}명에게 초대장을 보냈습니다.');
                }
                nav.pop();
              },
              child: Text(
                '초대',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.secondaryHeaderColor,
                ),
              ),
            ),

            // 소유자 전용 액션들
            if (isOwner) ...[
              // 수정 (진행 전에만)
              if (currentState < 1)
                CupertinoActionSheetAction(
                  onPressed: () async {
                    nav.pop();
                    final res = await context.push('/schedule/${scheduleProvider.schedule!['scheduleId']}/edit');

                    if (res == true) {
                      DialogManager.showBasicDialog(
                        title: '업데이트 성공',
                        content: "스케줄을 성공적으로 수정하였습니다",
                        confirmText: "확인",
                        onConfirm: () {
                          scheduleProvider.initializeSchedule(widget.scheduleId);
                        },
                      );
                    }
                  },
                  child: Text(
                    '수정',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.secondaryHeaderColor,
                    ),
                  ),
                ),

              // 삭제 (진행 전에만)
              if (currentState < 1)
                CupertinoActionSheetAction(
                  onPressed: () {
                    nav.pop();
                    DialogManager.showBasicDialog(
                      title: "일정 삭제 확인",
                      content: "삭제하면 다시 복구할 수 없어요.",
                      confirmText: "아니요, 취소할래요",
                      cancelText: "네, 삭제할게요",
                      onCancel: () {
                        scheduleProvider.deleteSchedule();
                      },
                    );
                  },
                  child: Text(
                    '삭제',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.secondaryHeaderColor,
                    ),
                  ),
                ),
            ] else ...[
              // 비소유자 전용 액션들
              CupertinoActionSheetAction(
                onPressed: () async {
                  nav.pop();
                  context.push('/report?targetId=${scheduleProvider.schedule!['scheduleId']}&type=schedule');
                },
                child: Text(
                  '신고',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.secondaryHeaderColor,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}