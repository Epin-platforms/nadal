import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';
import '../manager/project/Import_Manager.dart';

class NadalCommentTile extends StatefulWidget {
  const NadalCommentTile({
    super.key,
    required this.comment,
    required this.isReply,
    required this.provider,
  });

  final CommentProvider provider;
  final Map comment;
  final bool isReply;

  @override
  State<NadalCommentTile> createState() => _NadalCommentTileState();
}

class _NadalCommentTileState extends State<NadalCommentTile> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  bool _isExpanded = false;
  bool _isExpandable = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 5줄 이상일 경우에만 더보기 버튼 표시
    _checkIfExpandable();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _checkIfExpandable() {
    // 댓글 텍스트 길이 확인
    final commentText = widget.comment['text'].toString();
    // 대략 5줄 이상인지 판단 (평균 40자 기준)
    _isExpandable = commentText.length > 150.h &&
        commentText.trim().replaceAll(' ', '') != '삭제된댓글입니다.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentText = widget.comment['text'].toString();
    final isDeleted = commentText.trim().replaceAll(' ', '') == '삭제된댓글입니다.';

    return Padding(
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: 4.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: NadalProfileFrame(
              imageUrl: widget.comment['profileImage'],
              size: widget.isReply ? 28 : 34,
            ),
          ),

          const SizedBox(width: 10),

          // 댓글 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 정보 및 시간
                Row(
                  children: [
                    // 사용자 이름
                    Text(
                      TextFormManager.profileText(
                        widget.comment['displayName'],
                        widget.comment['displayName'],
                        widget.comment['birthYear'],
                        widget.comment['gender'],
                        useNickname: widget.comment['birthYear'] == null,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: widget.isReply ? 12.sp : 13.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    // 구분점
                    NadalDot(
                      color: theme.highlightColor,
                      size: widget.isReply ? 3.r : 4.r,
                    ),

                    // 시간
                    Text(
                      TextFormManager.timeAgo(item: widget.comment['createAt']),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: widget.isReply ? 11.sp : 12.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // 댓글 내용
                if (isDeleted)
                  Text(
                    commentText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 댓글 텍스트
                        Text(
                          commentText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: widget.isReply ? 13.sp : 14.sp,
                            height: 1.4,
                          ),
                          maxLines: _isExpanded || !_isExpandable ? null : 3,
                          overflow: _isExpanded || !_isExpandable
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),

                        // 더보기 버튼
                        if (_isExpandable)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                                if (_isExpanded) {
                                  _expandController.forward();
                                } else {
                                  _expandController.reverse();
                                }
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Row(
                                children: [
                                  Text(
                                    _isExpanded ? '접기' : '더보기',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                   SizedBox(width: 2.w),
                                  RotationTransition(
                                    turns: Tween(begin: 0.0, end: 0.5)
                                        .animate(_expandController),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 14.r,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // 답글 버튼
                if (!isDeleted && widget.comment['reply'] == null) ...[
                   SizedBox(height: 6.h),
                  InkWell(
                    onTap: () {
                      widget.provider.setReply(widget.comment['commentId']);
                      HapticFeedback.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_turn_down_right,
                            size: 12.sp,
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          ),
                           SizedBox(width: 4.w),
                          Text(
                            '답글',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 더보기 메뉴
          if (!isDeleted)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.comment['uid'] == FirebaseAuth.instance.currentUser!.uid) {
                  // 내 글이면 수정/삭제
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      final nav = Navigator.of(context);
                      return NadalSheet(
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              nav.pop();
                              widget.provider.setEditComment(widget.comment['commentId']);
                            },
                            child: Text(
                              '수정',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              nav.pop();
                              DialogManager.showBasicDialog(
                                title: '댓글을 삭제하시겠어요?',
                                content: '삭제한 댓글은 복구할 수 없습니다.',
                                confirmText: '삭제',
                                onConfirm: () {
                                  widget.provider.deleteComment(widget.comment['commentId']);
                                },
                                cancelText: '취소',
                              );
                            },
                            child: Text(
                              '삭제',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // 남이면 신고
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      final nav = Navigator.of(context);
                      return NadalSheet(
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              nav.pop();
                              context.push('/report?targetId=${widget.comment['commentId']}&type=user');
                            },
                            child: Text(
                              '신고',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  BootstrapIcons.three_dots_vertical,
                  size: 14,
                  color: theme.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}