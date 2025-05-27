import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/room/Room_Preview_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal.dart';
import 'package:my_sports_calendar/widget/Nadal_Circular.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';

import '../../../manager/project/Import_Manager.dart';

class RoomPreview extends StatelessWidget {
  const RoomPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomPreviewProvider>(context);
    final theme = Theme.of(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            backgroundColor: Colors.transparent,
            actions: [
              NadalReportIcon(
                onTap: (){
                  context.push('/report?targetId=${provider.room!['roomId']}&type=room');
                },
              )
            ],
          ),
          extendBodyBehindAppBar: true,
          body:
          provider.room != null ?
              Builder(
                builder: (context) {
                  if(provider.room!['roomImage'] != null){
                    precacheImage(NetworkImage(provider.room!['roomImage']), context);
                  }
                  return Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            image: DecorationImage(image:  provider.room!['roomImage'] == null ? AssetImage('assets/image/default/room_default.png') : NetworkImage(provider.room!['roomImage']), fit: BoxFit.cover)
                        ),
                      ),
                      // 드래그 가능한 바텀시트
                      DraggableScrollableSheet(
                        initialChildSize: 0.6, // 시작 높이 (10%)
                        minChildSize: 0.6,     // 최소 높이
                        maxChildSize: 0.8,     // 최대 확장 높이
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: ListView(
                              padding: EdgeInsets.only(top: 24.h, bottom: 100),
                              controller: scrollController,
                              shrinkWrap: true,
                              children: [
                                // 핸들
                                Center(
                                  child: Container(
                                    width: 40.w,
                                    height: 4.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).highlightColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 60.h,),
                                Text(provider.room!['roomName'], style: theme.textTheme.titleLarge,),
                                SizedBox(height: 6,),
                                Text('개설 ${DateFormat('yyyy.MM.dd').format(DateTime.parse(provider.room!['createAt']))}', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),),
                                SizedBox(height: 12,),
                                DefaultTextStyle(
                                  style: theme.textTheme.labelMedium!,
                                  child: Row(
                                    children: [
                                      Text('활동지역'),
                                      SizedBox(width: 4.w,),
                                      Text(TextFormManager.formToLocal(provider.room!['local'])),
                                      SizedBox(width: 4.w,),
                                      Text(provider.room!['city']),
                                      NadalDot(color: theme.highlightColor,),
                                      Text('멤버'),
                                      SizedBox(width: 4.w),
                                      Text('${provider.room!['memberCount']} /200')
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24.h,),
                                Row(
                                  children: [
                                    NadalProfileFrame(imageUrl: provider.room!['creatorProfile'], size: 40.r,),
                                    SizedBox(width: 8,),
                                    Text('${provider.room!['creatorNickName'] ?? '(알수없음)'}', style: theme.textTheme.bodyMedium,)
                                  ],
                                ),
                                SizedBox(height: 12,),
                                Text(provider.room!['description'], style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),),
                                SizedBox(height: 12,),
                                Text(provider.room!['tag'], style: theme.textTheme.labelMedium?.copyWith(color: ThemeManager.infoColor),),
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: SafeArea(
                              child: NadalButton(isActive: true, title: '클럽 가입하기', onPressed: (){
                                DialogManager.showBasicDialog(title: '클럽에 가입해볼까요?', content: '클럽 일정과 소식이 바로 공유돼요', confirmText: '	지금 입장하기', cancelText: '조금 있다가요',
                                  onConfirm: () async{
                                      provider.registerStart("");
                                  }
                                );
                              },)
                          )
                      )
                    ],
                  );
                }
              ) :
          SafeArea(
              child: Center(
                child: NadalCircular()
              )
          )
        )
    );
  }
}
