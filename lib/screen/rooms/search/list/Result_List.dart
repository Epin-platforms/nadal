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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            onTap: () {

              if(context.read<RoomsProvider>().rooms!.containsKey(item['roomId'])){
                context.push('/room/${item['roomId']}');
              }else{
                context.push('/previewRoom/${item['roomId']}');
              }
              HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 룸 이미지
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                        size: 70,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 5),

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

                        const SizedBox(height: 8),

                        // 태그 및 멤버 카운트
                        Row(
                          children: [
                            // 태그 표시
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

                            const Spacer(),

                            // 멤버 수 표시
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
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
