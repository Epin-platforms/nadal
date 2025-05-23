import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';

class ResultList extends StatelessWidget {
  const ResultList({super.key, required this.provider});
  final SearchRoomProvider provider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return
    provider.resultRooms.isEmpty && provider.submitted ?
        
    SizedBox(
      height: 300,
      child: NadalEmptyList(title: "\"${provider.lastSearch}\" 관련 클럽을 찾을 수 없어요", subtitle: "다른 키워드로 다시 검색해볼까요?",),
    ) :
    
    ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: provider.resultRooms.length,
      itemBuilder: (context, index){
        final item = provider.resultRooms[index];
        return Container(
          margin:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () {
              if(context.read<RoomsProvider>().rooms!.containsKey(item['roomId'])){
                context.push('/room/${item['roomId']}');
              }else{
                context.push('/previewRoom/${item['roomId']}');
              }
              HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 룸 이미지
                  Container(
                    width: 70.r,
                    height: 70.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: NadalRoomFrame(
                        imageUrl: item['roomImage'],
                        size: 70.r,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 룸 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 룸 이름
                        Text(
                          item['roomName'],
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 5.h),

                        // 룸 설명
                        Text(
                          item['description'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 8.h),

                        // 태그 및 멤버 카운트
                        Row(
                          children: [
                            // 태그 표시
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['tag'],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w,),
                            // 멤버 수 표시
                            Row(
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 14.r,
                                  color: Colors.grey,
                                ),
                                 SizedBox(width: 4.w),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${item['memberCount']}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '/200',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
