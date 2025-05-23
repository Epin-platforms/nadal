import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/model/qna/Qna_Model.dart';

import '../../manager/project/Import_Manager.dart';

class QnaDetailPage extends StatefulWidget {
  const QnaDetailPage({super.key, required this.qnaModel});
  final QnaModel qnaModel;
  @override
  State<QnaDetailPage> createState() => _QnaDetailPageState();
}

class _QnaDetailPageState extends State<QnaDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NadalAppbar(
        title: '문의 상세',
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildQnaDetails(context, widget.qnaModel)
      ),
    );
  }

  Widget _buildQnaDetails(BuildContext context, QnaModel qna) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final hasAnswer = qna.answer != null && qna.answer!.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 표시 배지
            _buildStatusBadge(hasAnswer),
            SizedBox(height: 16.h),

            // 문의 정보 카드
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 문의 제목
                    Text(
                      qna.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8.h),

                    // 문의 날짜
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16.r,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          dateFormat.format(qna.createAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // 구분선
                    Divider(height: 1.h),
                    SizedBox(height: 16.h),

                    // 문의 내용
                    Text(
                      qna.question,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // 답변 섹션
            if (hasAnswer) _buildAnswerSection(context, qna)
            else _buildAwaitingAnswerSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool hasAnswer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: hasAnswer
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        hasAnswer ? '답변 완료' : '답변 대기중',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: hasAnswer
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildAnswerSection(BuildContext context, QnaModel qna) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '답변',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16.h),

        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 답변 날짜 및 담당자
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.r,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      widget.qnaModel.managerName ?? '고객지원팀',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.access_time,
                      size: 16.r,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      dateFormat.format(qna.answerAt!),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // 답변 내용
                Text(
                  qna.answer!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // 추가 문의 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context, {
                'action' : 'write'
              });
            },
            child: Text('추가 문의하기'),
          ),
        ),
      ],
    );
  }

  Widget _buildAwaitingAnswerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '답변',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16.h),

        Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 48.r,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 16.h),
                Text(
                  '답변 대기중',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '최대한 빠르게 답변 드리겠습니다',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (_){
          return NadalSheet(actions: [
            CupertinoActionSheetAction(onPressed: (){
              Navigator.pop(context);
              _showDeleteConfirmDialog(context);
            }, child: Text('삭제', style:Theme.of(context).textTheme.labelLarge,))
          ]);
        }
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('문의 삭제'),
        content: Text('이 문의를 삭제하시겠습니까? 삭제된 문의는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'action' : 'delete',
                'qid' : widget.qnaModel.qid
              }); // 상세 페이지 닫기
            },
            child: Text('삭제', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
