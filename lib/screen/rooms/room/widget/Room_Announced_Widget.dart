import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../manager/project/Import_Manager.dart';

class RoomAnnouncedWidget extends StatefulWidget {
  const RoomAnnouncedWidget({super.key, required this.announce});
  final Map announce;

  @override
  State<RoomAnnouncedWidget> createState() => _RoomAnnouncedWidgetState();
}

class _RoomAnnouncedWidgetState extends State<RoomAnnouncedWidget> {
  bool isExpanded = false;
  bool showToggle = false;


  @override
  void initState() {
    super.initState();
    // 높이 측정은 build 후에 해야 하므로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox;
      final height = renderBox.size.height;
      if (height > 80) {
        setState(() {
          showToggle = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announce = widget.announce;
    final description = announce['description'] ?? '내용없음';

    final displayText = TextFormManager.profileText(
      announce['displayName'],
      announce['displayName'],
      announce['birthYear'],
      announce['gender'],
      useNickname: announce['gender'] == null,
    );

    return GestureDetector(
      onTap: ()=> context.push('/schedule/${announce['scheduleId']}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 상단 Row (작성자 + 날짜 + optional toggle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(width: 12.w,),
                    Container(
                      padding: EdgeInsetsGeometry.symmetric(vertical: 2.r, horizontal: 4.w),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Theme.of(context).colorScheme.secondary
                      ),
                      child: Text('공지', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondary, fontSize: 8.sp),),
                    ),
                    SizedBox(width: 4.w,),
                    Text('작성자: $displayText', style: theme.textTheme.labelSmall),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('yyyy년 MM월 dd일', 'ko_KR')
                          .format(DateTimeManager.parseUtcToLocal(announce['createAt'])),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                    ),
                    if (showToggle)
                      IconButton(
                        icon: Icon(isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
      
            const SizedBox(height: 4),
      
            /// 공지 텍스트 (줄임 여부)
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 12.w),
              child: AnimatedCrossFade(
                crossFadeState: isExpanded || !showToggle
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                firstChild: Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
                secondChild: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


