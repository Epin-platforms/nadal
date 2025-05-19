import 'package:my_sports_calendar/screen/schedule/participation/team/Team_Select.dart';

import '../../../manager/project/Import_Manager.dart';

class ParticipationTeam extends StatefulWidget {
  const ParticipationTeam({super.key, required this.provider});
  final ScheduleProvider provider;

  @override
  State<ParticipationTeam> createState() => _ParticipationTeamState();
}

class _ParticipationTeamState extends State<ParticipationTeam> {
  late UserProvider userProvider;
  bool _editMode = false;

  _onParticipation() async{
    final team = await Navigator.of(context).push(MaterialPageRoute(builder: (context)=> TeamSelect(roomId: widget.provider.schedule?['roomId'], scheduleId: widget.provider.schedule?['scheduleId'])));

    if(team != null){
      // 참가 로직
      final res = await widget.provider.participateTeamSchedule(team);

      if (res == 'complete') {
        await widget.provider.updateMembers;
        userProvider.fetchMySchedules(DateTime.parse(widget.provider.schedule!['startDate']).toLocal(), force: true);
      }else if(res == 'exist'){
        DialogManager.showBasicDialog(
          title: '앗, 이미 참가 중인 멤버에요!',
          content: '다른 멤버를 선택해 주세요 🙂',
          confirmText: '알겠어요',
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    final Map<String, List<dynamic>>? teams = widget.provider.teams; //{'teamName' : [{memberData Map<dynamic>}, {..}]}
    final theme = Theme.of(context);
    final isJoined = widget.provider.scheduleMembers!.containsKey(userProvider.user!['uid']);

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: _editMode ?  '참가자 수정' : '현재 참가 팀 보기',
          actions: [
            if(widget.provider.schedule!['uid'] == context.read<UserProvider>().user!['uid'] && !_editMode && (widget.provider.schedule!['state'] ?? 0) == 0)
              NadalIconButton(
                onTap: (){
                  setState(() {
                    _editMode = true;
                  });
                },
                icon: BootstrapIcons.gear,
              )
            else if(_editMode)
              TextButton(
                  style: ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 3, horizontal: 3)),
                      alignment: AlignmentDirectional.centerEnd
                  ),
                  onPressed: () => setState(() => _editMode = false),
                  child: Text('완료')
              )
          ],
        ),
        body: SafeArea(
            child: teams != null && teams.isNotEmpty
                ? RefreshIndicator(
              onRefresh: () => widget.provider.updateMembers,
              child: ListView.builder(
                itemCount: teams.keys.length,
                itemBuilder: (context, index) {
                  final teamName = teams.keys.elementAt(index);
                  final teamMembers = teams[teamName]!; // 팀원 리스트

                  // 팀의 승인 상태 (모든 멤버가 승인되어야 팀이 승인됨)
                  final allApproved = teamMembers.every((member) => member['approval'] == 1);

                  // 내 팀인지 확인
                  final isMyTeam = teamMembers.any((member) => member['uid'] == userProvider.user!['uid']);

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: allApproved
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.dividerColor,
                          width: 1
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 팀 헤더
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Text(
                                teamName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              // 팀 승인 상태
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: allApproved
                                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                      : theme.colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  allApproved ? '승인됨' : '승인 대기',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: allApproved
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ),
                              if (isMyTeam)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: NadalMeTag(),
                                ),
                            ],
                          ),
                          trailing: _editMode
                              ? Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: allApproved ? theme.colorScheme.error : theme.colorScheme.secondary
                            ),
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                            child: Text(
                              allApproved ? '거절' : '승인',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          )
                              : null,
                          onTap: _editMode ? () {
                            // 팀 승인/거절 다이얼로그
                            if (allApproved) {
                              DialogManager.showBasicDialog(
                                  title: '팀 참가를 거절할까요?',
                                  content: '거절 시 팀 전체가 일정 시작 시 자동으로 리스트에서 제외됩니다',
                                  confirmText: '확인',
                                  cancelText: '취소',
                                  onConfirm: () {
                                    // 팀 전체 거절 처리
                                    for (var member in teamMembers) {
                                      widget.provider.memberParticipation(member, false);
                                    }
                                  }
                              );
                            } else {
                              DialogManager.showBasicDialog(
                                  title: '팀 참가를 승인할까요?',
                                  content: '승인하면 팀 전체에게 안내 메시지가 발송됩니다.',
                                  confirmText: '확인',
                                  cancelText: '취소',
                                  onConfirm: () {
                                    // 팀 전체 승인 처리
                                    for (var member in teamMembers) {
                                      widget.provider.memberParticipation(member, true);
                                    }
                                  }
                              );
                            }
                          } : null,
                        ),

                        // 팀원 목록
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: teamMembers.length,
                          itemBuilder: (context, idx) {
                            final member = teamMembers[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                              dense: true,
                              leading: NadalProfileFrame(
                                imageUrl: member['profileImage'],
                                size: 36,
                              ),
                              title: Text(
                                TextFormManager.profileText(
                                    member['nickName'],
                                    member['name'],
                                    member['birthYear'],
                                    member['gender'],
                                    useNickname: widget.provider.schedule?['useNickname'] == 1
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1,
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                              trailing: member['uid'] == userProvider.user!['uid']
                                  ? NadalMeTag()
                                  : member['approval'] == 0
                                  ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '대기중',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              )
                                  : null,
                            );
                          },
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            )
                : NadalEmptyList(
              title: '아직 참가 팀이 없어요',
              subtitle: '첫 번째 팀이 되어보세요!',
              actionText: '지금 참가하기',
              onAction: _editMode && (widget.provider.schedule!['state'] ?? 0) == 0 ? null : () async {
                _onParticipation();
              },
            )
        ),
        floatingActionButton: Visibility(
            visible: teams != null && teams.isNotEmpty && (widget.provider.schedule?['state'] ?? 0) == 0,
            child: FloatingActionButton.extended(
              onPressed: () async {
                if (isJoined) {
                  // 참가 취소 로직
                  widget.provider.cancelTeamParticipation();
                } else {
                  _onParticipation();
                }
              },
              label: Text(
                isJoined ? '참가 취소하기' : '스케줄 참가하기',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              icon: Icon(
                  isJoined ? Icons.close : Icons.check_circle_outline,
                  color: Colors.white
              ),
              backgroundColor: isJoined
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary.withValues(alpha: 0.9),
            )
        ),
      ),
    );
  }
}