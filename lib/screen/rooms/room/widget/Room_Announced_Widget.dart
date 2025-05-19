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

  final _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 높이 측정은 build 후에 해야 하므로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _textKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox;
        final height = renderBox.size.height;
        if (height > 80) {
          setState(() {
            showToggle = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announce = widget.announce;
    final description = announce['description'] ?? '';

    final displayText = TextFormManager.profileText(
      announce['displayName'],
      announce['displayName'],
      announce['birthYear'],
      announce['gender'],
      useNickname: announce['gender'] == null,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 상단 Row (작성자 + 날짜 + optional toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayText, style: theme.textTheme.labelMedium),
              Row(
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일', 'ko_KR')
                        .format(DateTime.parse(announce['createAt']).toLocal()),
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
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
          AnimatedCrossFade(
            crossFadeState: isExpanded || !showToggle
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Text(
              description,
              key: _textKey,
              style: theme.textTheme.bodySmall,
            ),
            secondChild: Text(
              description,
              key: _textKey,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
