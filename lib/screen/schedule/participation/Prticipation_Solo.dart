import 'package:my_sports_calendar/manager/game/Game_Manager.dart';

import '../../../manager/project/Import_Manager.dart';

class ParticipationSolo extends StatefulWidget {
  const ParticipationSolo({super.key, required this.provider});
  final ScheduleProvider provider;

  @override
  State<ParticipationSolo> createState() => _ParticipationSoloState();
}

class _ParticipationSoloState extends State<ParticipationSolo> {
   bool _editMode = false;

   @override
  void initState() {
    widget.provider.updateMembers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final members = widget.provider.scheduleMembers!.entries.toList();
    final theme = Theme.of(context);
    final isJoined = widget.provider.scheduleMembers!.containsKey(userProvider.user!['uid']);

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: _editMode ?  '참가자 수정' : '현재 참가자 보기',
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
                  onPressed: ()=> setState(()=>  _editMode = false), child: Text('완료')
              )
          ],
        ),
        body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Builder(
                      builder: (context){
                        final item = widget.provider.schedule!;
                        final game = item['isKDK'] == 1 && item['isSingle'] == 1 ? '대진표단식' : item['isKDK'] == 1 && item['isSingle'] == 0 ? '대진표복식' : null;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if(game != null)
                                Row(
                                  children: [
                                    Text(
                                      '인원제한',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                                    ),
                                    SizedBox(width: 12),
                                    RichText(
                                      text: TextSpan(
                                        style: theme.textTheme.bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: '${widget.provider.scheduleMembers?.values.where((e)=> e['approval'] == 1).length ?? 0}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: (game == '대진표단식' && widget.provider.scheduleMembers!.length == 13) ||
                                                  (game == '대진표복식' && widget.provider.scheduleMembers!.length == 16)
                                                  ? theme.colorScheme.error
                                                  : theme.textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' /${game == '대진표단식' ? '${GameManager.max_kdk_single_member}' : '${GameManager.max_kdk_double_member}'}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.hintColor,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              Row(
                                children: [
                                  // 남자 제한
                                  if(widget.provider.schedule?['maleLimit'] != null && widget.provider.schedule?['useGenderLimit'] == 1)
                                    Row(
                                      children: [
                                        Icon(Icons.male, size: 18, color: Colors.blue),
                                        SizedBox(width: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.bodyMedium,
                                            children: [
                                              TextSpan(
                                                text: '${widget.provider.scheduleMembers!.values.where((e) => e['gender'] == 'M' && e['approval'] == 1).length}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: (widget.provider.schedule?['maleLimit'] != null &&
                                                      widget.provider.scheduleMembers!.values.where((e) => e['gender'] == 'M' && e['approval'] == 1).length >= widget.provider.schedule?['maleLimit'])
                                                      ? theme.colorScheme.error
                                                      : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '/${widget.provider.schedule?['maleLimit'] ?? '-'}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.hintColor,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  // 여자 제한
                                  if(widget.provider.schedule?['femaleLimit'] != null && widget.provider.schedule?['useGenderLimit'] == 1)
                                    Row(
                                      children: [
                                        SizedBox(width: 12),
                                        Icon(Icons.female, size: 18, color: Colors.pink),
                                        SizedBox(width: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.bodyMedium,
                                            children: [
                                              TextSpan(
                                                text: '${widget.provider.scheduleMembers?.values.where((e) => e['gender'] == 'F' && e['approval'] == 1).length ?? 0}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: (widget.provider.schedule?['femaleLimit'] != null &&
                                                      widget.provider.scheduleMembers!.values.where((e) => e['gender'] == 'F' && e['approval'] == 1).length >= widget.provider.schedule?['femaleLimit'])
                                                      ? theme.colorScheme.error
                                                      : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '/${widget.provider.schedule?['femaleLimit'] ?? '-'}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.hintColor,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              )

                            ],
                          ),
                        );
                      }
                  ),
                ),
                Expanded(child:
                members.isNotEmpty ?
                RefreshIndicator(
                  onRefresh: ()=> widget.provider.updateMembers(),
                  child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context,index){
                        final item = members[index].value;
                        if(_editMode){
                          return IgnorePointer(
                            ignoring: widget.provider.isOwner &&  item['uid'] == FirebaseAuth.instance.currentUser!.uid,
                            child: ListTile(
                              onTap: (){
                                if(item['approval'] == 0){
                                  DialogManager.showBasicDialog(title: '참가 요청을 승인할까요?', content: '	승인하면 참가자에게 안내 메시지가 발송됩니다.', confirmText: '확인', cancelText: '취소',
                                      onConfirm: (){
                                        widget.provider.memberParticipation(item, true);
                                      }
                                  );
                                }else{
                                  DialogManager.showBasicDialog(title: '참가 요청을 거절할까요?', content: '거절 시 참가자는 일정 시작 시 자동으로 리스트에서 제외됩니다', confirmText: '확인', cancelText: '취소',
                                      onConfirm: (){
                                        widget.provider.memberParticipation(item, false);
                                      });
                                }
                              },
                              contentPadding: EdgeInsets.symmetric(vertical: 3, horizontal: 16),
                              leading: NadalProfileFrame(imageUrl: item['profileImage'], size: 45,),
                              trailing:
                              widget.provider.isOwner && item['uid'] == FirebaseAuth.instance.currentUser!.uid ?
                               NadalMeTag()
                                  : Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: item['approval'] == 0 ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error
                                ),
                                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                child: Text(item['approval'] == 0 ? '승인' : '거절', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xffffffff), fontWeight: FontWeight.w600),),
                              ),
                              title: Text(TextFormManager.profileText(item['nickName'], item['name'], item['birthYear'], item['gender'], useNickname: widget.provider.schedule?['useNickname'] == 1), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1, fontWeight: FontWeight.w500),),
                            ),
                          );
                        }else{
                          return ListTile(
                            onTap: (){
                                context.push('/user/${item['uid']}');
                            },
                            contentPadding: EdgeInsets.symmetric(vertical: 3, horizontal: 16),
                            leading: NadalProfileFrame(imageUrl: item['profileImage'], size: 45,),
                            trailing: userProvider.user!['uid'] == item['uid'] ? NadalMeTag() : null,
                            title: Text(TextFormManager.profileText(item['nickName'], item['name'], item['birthYear'], item['gender'], useNickname: widget.provider.schedule?['useNickname'] == 1), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1, fontWeight: FontWeight.w500),),
                            subtitle: Text(item['approval'] == 1 ? '참가 승인된 사용자' : '참가 거절된 사용자', style: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1, color: item['approval'] == 1 ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error),),
                          );
                        }

                      }
                  ),
                ) :
                NadalEmptyList(
                  title: '아직 참가자가 없어요',
                  subtitle: '	첫 번째 참가자가 되어보세요!',
                  actionText: '지금 참가하기',
                  onAction: _editMode  && (widget.provider.schedule!['state'] ?? 0) == 0 ?  null : () async{
                    final res = await widget.provider.participateSchedule();
                    if(res == 'complete'){
                      await widget.provider.updateMembers();
                    }
                  },
                )
                )
              ],
            )
        ),
        floatingActionButton: Visibility(
            visible: widget.provider.scheduleMembers!.isNotEmpty && (widget.provider.schedule?['state'] ?? 0) == 0,
            child: FloatingActionButton.extended(
              onPressed: () async{
                if (isJoined) {
                  // 참가 취소 로직
                  widget.provider.cancelParticipation();

                } else {
                  // 참가 로직
                  final res = await widget.provider.participateSchedule();
                  if(res == 'complete'){
                    await widget.provider.updateMembers();
                    userProvider.fetchMySchedules(DateTime.parse(widget.provider.schedule!['startDate']), force: true);
                  }
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
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
            )
        ),
      ),
    );
  }
}
