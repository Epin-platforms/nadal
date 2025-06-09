import 'package:my_sports_calendar/screen/league/League_Widget.dart';

import '../../manager/project/Import_Manager.dart';
import '../../widget/Nadal_Room_Frame.dart';

class QuickChatMore extends StatefulWidget {
  const QuickChatMore({super.key, required this.homeProvider});
  final HomeProvider homeProvider;

  @override
  State<QuickChatMore> createState() => _QuickChatMoreState();
}

class _QuickChatMoreState extends State<QuickChatMore> {

  @override
  void initState() {
    widget.homeProvider.fetchHotQuickChatRooms();
    widget.homeProvider.fetchRanking();
    super.initState();
  }
 
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsetsGeometry.only(left: 16.w, top: 14.h, bottom: 12.h, right: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('개최중인 대회🎾', style: Theme.of(context).textTheme.titleMedium,),
                  InkWell(
                    onTap: ()=> context.push('/league'),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: EdgeInsetsGeometry.symmetric(vertical: 4.h, horizontal: 8.w),
                      child: Text('더보기 >', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary),),
                    ),
                  )
                ],
              )),
        ),
        SliverToBoxAdapter(
          child: LeagueWidget(),
        ),
        widget.homeProvider.hotQuickChatRooms == null ?
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300.h,
                child: Center(
                  child: NadalCircular(),
                ),
              ),
            ) :
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsetsGeometry.only(left: 16.w, top: 14.h, bottom: 12.h),
              child: Text('요즘 핫한 인기방🔥', style: Theme.of(context).textTheme.titleMedium,)),
        ),
          if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: NadalEmptyList(title: '아직 인기방이 없어요',
                  subtitle: '지금 바로 방을 만들고 사람을 모아 인기방을 운영해보세요',
                  actionText: '번개방 만들기',
                  onAction: ()=> context.push('/createRoom?isOpen=TRUE')),
              ),
            )
          else if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isNotEmpty)
            SliverList.builder(
                itemCount: widget.homeProvider.hotQuickChatRooms!.length,
                itemBuilder: (context, index){
                  final item = widget.homeProvider.hotQuickChatRooms![index];
                  return ListTile(
                    onTap: () => context.push('/previewRoom/${item['roomId']}'),
                    leading: NadalRoomFrame(imageUrl: item['roomImage']),
                    title: Text(
                      item['roomName'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 36.h),
                            child: Text(
                              _getItemDescription(item),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Text(
                            '${item['memberCount']}/200',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }
            ),
        if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w, vertical: 8.h),
              child: InkWell(
                onTap: ()=> widget.homeProvider.fetchHotQuickChatRooms(),
                child: NadalSolidContainer(
                  height: 32.h,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16.r, color: Theme.of(context).secondaryHeaderColor,),
                      SizedBox(width: 4.w,),
                      Text('다른 인기방 보기', style: Theme.of(context).textTheme.labelMedium,),
                    ],
                  ),
                ),
              ),
            ),
          ),
        //광고 넣기 네이티브로 큰광고 //만약 advertisement에서버광고가있다면 우선 출력 아니면 네이티브 출럭

        if(widget.homeProvider.ranking.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsetsGeometry.only(left: 16.w, top: 14.h, bottom: 12.h),
              child: Text('🏆오늘의 랭킹', style: Theme.of(context).textTheme.titleMedium,)),
        ),
        if(widget.homeProvider.ranking.isNotEmpty)
        SliverList.builder(
            itemCount: widget.homeProvider.ranking.length,
            itemBuilder: (context, index){
              final member = widget.homeProvider.ranking[index];
              return ListTile(
                leading: NadalProfileFrame(
                  imageUrl: member['profileImage'],
                  size: 46.r,
                ),
                title: Text('${_getRankingBadge(index)}${member['nickName']}', style: Theme.of(context).textTheme.titleMedium,),
                subtitle: Text(member['roomName'] ?? '무소속', style: Theme.of(context).textTheme.bodySmall,),
                trailing: Text('${(member['totalFluctuation'] as num) > 0 ? '+' : ''}${(member['totalFluctuation'] as num).toDouble().toStringAsFixed(2)}', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: (member['totalFluctuation'] as num) > 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error
                ),),
              );
            }
        )
      ],
    );
  }

  String _getRankingBadge(int rank){
    switch(rank){
      case 0 : return '🥇';
      case 1 : return '🥈';
      case 2 : return '🥉';
      default : return '';
    }
  }


  /// 아이템 설명 생성
  String _getItemDescription(dynamic item) {
    final description = item['description'] as String;
    final tag = item['tag'] as String;

    if (description.isNotEmpty) {
      return description;
    } else if (tag.isNotEmpty) {
      return tag;
    } else {
      return '정보없음';
    }
  }
}
