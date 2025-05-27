import 'package:animate_do/animate_do.dart';
import 'package:my_sports_calendar/provider/game/Team_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';
import 'package:my_sports_calendar/widget/Search_Text_Field.dart';

import '../../../../manager/project/Import_Manager.dart';

class TeamSelect extends StatefulWidget {
  const TeamSelect({super.key, required this.roomId, required this.scheduleId});
  final int roomId;
  final int scheduleId;

  @override
  State<TeamSelect> createState() => _TeamSelectState();
}

class _TeamSelectState extends State<TeamSelect> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
        create: (_)=> TeamProvider(widget.roomId, widget.scheduleId),
        builder: (context, child){
          final teamProvider = Provider.of<TeamProvider>(context);

          if(teamProvider.teams == null){
            return GestureDetector(
              onTap: ()=> Navigator.pop(context),
              child: Material(
                child: Center(
                  child: NadalCircular(),
                ),
              ),
            );
          }


          return IosPopGesture(
              child: Scaffold(
                appBar: NadalAppbar(
                  title: '팀 선택',
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 12,),
                              //팀만들기 카드
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: theme.cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor,
                                      blurRadius: 10,
                                      spreadRadius: 0
                                    )
                                  ]
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(16,16,16,8),
                                  child: Column(
                                    crossAxisAlignment:  CrossAxisAlignment.start,
                                    children: [
                                      Text('팀 만들기', style: theme.textTheme.titleSmall,),
                                      SizedBox(height: 16,),
                                      NadalTextField(controller: _controller, label: '팀명', maxLength: 10, helper: '2~10자로 입력해주세요',),
                                      if(teamProvider.selectUser != null)...[
                                        SizedBox(height: 16,),
                                        Text('선택된 사용자', style: theme.textTheme.titleSmall,),
                                        SizedBox(height: 8,),
                                        Builder(
                                          builder: (context) {
                                            final item = teamProvider.members!.where((e)=> e['uid'] == teamProvider.selectUser).first;
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: NadalProfileFrame(imageUrl: item['profileImage']),
                                              title: Text(TextFormManager.profileText(item['displayName'], item['displayName'], item['birthYear'], item['gender'], useNickname: item['useNickname'] == 1)),
                                              subtitle: Text(item['isParticipation'] == 1 ? '이 일정 참가중' : '선택가능'),
                                              trailing: IconButton(onPressed: ()=> teamProvider.setSelectUser(null), icon: Icon(BootstrapIcons.x_circle), iconSize: 18,),
                                            );
                                          }
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: NadalButton(
                                        onPressed: () async{
                                          final user = await showModalBottomSheet(
                                              showDragHandle: true,
                                              useRootNavigator: false,
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (bottomSheetContext) {
                                                // 상위 컨텍스트의 TeamProvider를 가져옵니다
                                                final teamProvider = Provider.of<TeamProvider>(context, listen: false);

                                                // value 생성자를 사용하여 동일한 인스턴스를 전달합니다
                                                return ChangeNotifierProvider.value(
                                                  value: teamProvider,
                                                  child: Builder(
                                                    builder: (providerContext) {
                                                      // 이 Builder 컨텍스트는 ChangeNotifierProvider 아래에 있으므로
                                                      // listen: true로 TeamProvider의 변경사항을 구독할 수 있습니다
                                                      return MemberList(
                                                        teamProvider: Provider.of<TeamProvider>(providerContext, listen: true),
                                                      );
                                                    },
                                                  ),
                                                );
                                              }
                                          );

                                          if(user != null){
                                            teamProvider.setSelectUser(user);
                                          }
                                        },
                                        margin: EdgeInsets.zero,
                                        isActive: true, color: ThemeManager.infoColor, title: '팀원선택', height: 40.h,),
                                    ),
                                    if(teamProvider.selectUser != null)...[
                                      SizedBox(width: 8,),
                                      Flexible(
                                        child: NadalButton(
                                          margin: EdgeInsets.zero,
                                          onPressed: (){
                                            if(_controller.text.replaceAll(' ', '').replaceAll('\n', '').trim().length < 2 ||
                                                _controller.text.replaceAll(' ', '').replaceAll('\n', '').trim().length > 10){
                                              DialogManager.showBasicDialog(title: '흠.. 팀명이 이상해요 🤔', content: '다시 한번 확인해주세요', confirmText: '확인');
                                              return;
                                            }

                                            DialogManager.showBasicDialog(
                                              onConfirm: (){
                                                teamProvider.createTeam(_controller.text);
                                                _controller.clear();
                                              },
                                              title: '팀 생성, 바로 갈까요?',
                                              content: '한 번 만들면 상대방에게도 보여요!',
                                              confirmText: '만들게요!',
                                              cancelText: '앗! 잠깐만요',
                                            );
                                          },
                                          isActive: true, color: ThemeManager.accentLight, title: '팀 만들기', height: 40.h,),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                  
                              SizedBox(height: 16.h,),
                              Padding(padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
                                child: Text('나의 팀', style: theme.textTheme.titleMedium,),
                              ),
                              if(teamProvider.teams!.isEmpty)
                                SizedBox(
                                  height: 300,
                                  child: NadalEmptyList(title: '아직 이방엔 나의 팀이 없어요', subtitle: '지금 바로 팀원을 저장하고 경기를 진행해보세요',),
                                )
                              else
                                ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: teamProvider.teams!.length,
                                    itemBuilder: (context, index){
                                      final team = teamProvider.teams![index];
                                      return ListTile(
                                        onTap: (){
                                          if(teamProvider.selectMyTeam == team['teamId']){
                                            teamProvider.setMyTeam(null);
                                          }else{
                                            teamProvider.setMyTeam(team['teamId']);
                                          }
                                        },
                                        leading: NadalProfileFrame(imageUrl: team['profileImage']),
                                        title: Text(TextFormManager.profileText(team['displayName'], team['displayName'], team['birthYear'], team['gender'], useNickname: team['useNickname'] == 1)),
                                        subtitle: Text('팀명: ${team['teamName']}'),
                                        trailing:
                                        Container(
                                          height: 24, width: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.highlightColor
                                          ),
                                          padding: EdgeInsets.all(3),
                                          child: FittedBox(
                                            child: ZoomIn(
                                              animate: teamProvider.selectMyTeam == team['teamId'],
                                              child: Icon(
                                                BootstrapIcons.check_circle_fill, color: theme.colorScheme.primary,
                                              ),
                                            )
                                          ),
                                        )
                                      );
                                    }
                                )
                            ],
                          ),
                        ),
                      ),
                      NadalButton(
                          onPressed: (){
                            if(teamProvider.selectMyTeam != null){
                              Navigator.pop(context, teamProvider.selectMyTeam);
                            }
                          },
                          isActive: teamProvider.selectMyTeam != null,
                          title: '팀으로 참가하기', 
                      ),
                    ],
                  ),
                ),
              )
          );
        },
    );
  }
}


class MemberList extends StatefulWidget {
  const MemberList({super.key, required this.teamProvider});
  final TeamProvider teamProvider;
  @override
  State<MemberList> createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  final _searchController = TextEditingController(); 
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(mounted){
        _scroll.addListener(_scrollListener);
        widget.teamProvider.fetchRoomMember();
      }
      Future.delayed(const Duration(milliseconds: 300), ()=> setState(() {}));
    });
    super.initState();
  }


  void _scrollListener() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 50) {
      // 스크롤이 끝에 도달하거나 거의 다 도달했을 때 실행
      widget.teamProvider.fetchRoomMember();
    }
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.teamProvider.fetchResult(value); // ← 1초 후 실행
    });
  }

  @override
  Widget build(BuildContext context) {

    if(widget.teamProvider.members == null){
      return Center(
        child: NadalCircular(),
      );
    }
    
    return Column(
      children: [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchTextField(
              onChanged: (value){
                onSearchChanged(value);
              },
              controller: _searchController, hintText: '닉네임/이름 검색..',)),
        Expanded(
          child:
          widget.teamProvider.searching ?
              Center(
                child: NadalCircular(),
              ) :
          widget.teamProvider.lastValue.isNotEmpty &&
          widget.teamProvider.result.isEmpty ?
            NadalEmptyList(title: '찾으시는 사용자거 없어요', subtitle: '다른 사용자를 검색해보세요',)
          : ListView.builder(
              controller: _scroll,
              itemCount:
              widget.teamProvider.lastValue.isNotEmpty ?
              widget.teamProvider.result.length : widget.teamProvider.members!.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index){
                final item =  widget.teamProvider.lastValue.isNotEmpty ?
                widget.teamProvider.result[index] : widget.teamProvider.members![index];
                return ListTile(
                  onTap: (){
                    Navigator.pop(context, item['uid']);
                  },
                  leading: NadalProfileFrame(imageUrl: item['profileImage']),
                  title: Text(TextFormManager.profileText(item['displayName'], item['displayName'], item['birthYear'], item['gender'], useNickname: item['useNickname'] == 1)),
                  subtitle: Text(item['isParticipation'] == 1
                      ? '이 일정에 참가 중이에요'
                      : '이 일정에 참가하지 않았어요'),
                );
              }
          ),
        ),
      ],
    );
  }
}
