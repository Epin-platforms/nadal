import 'package:intl/intl.dart';
import 'package:my_sports_calendar/model/qna/Qna_Model.dart';
import 'package:my_sports_calendar/provider/qna/Qna_Provider.dart';

import '../../manager/project/Import_Manager.dart';

class QnaList extends StatefulWidget {
  const QnaList({super.key});

  @override
  State<QnaList> createState() => _QnaListState();
}

class _QnaListState extends State<QnaList> {
  late QnaProvider provider;
  // FAQ 섹션 확장/축소 상태
  bool _isFaqExpanded = true;

  // 새 문의 작성 페이지로 이동
  void _navigateToNewInquiry() {
    // 실제 앱에서는 네비게이션 로직으로 대체
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('새 문의 작성 페이지로 이동합니다')),
    );
  }

  // 문의 상세 페이지로 이동
  void _navigateToInquiryDetail(QnaModel inquiry) {
    // 실제 앱에서는 네비게이션 로직으로 대체
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('문의 상세 페이지로 이동: ${inquiry.title}')),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_)=> provider.fetchQnaList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_)=> QnaProvider(),
      builder: (context, child) {
        provider = Provider.of<QnaProvider>(context);

        if(provider.qs == null){
          return Material(
            child:  Center(
              child: NadalCircular(),
            ),
          );
        }

        return IosPopGesture(
            child: Scaffold(
              appBar: NadalAppbar(
                title: '문의 및 FAQ',
              ),
              body: SafeArea(
                  child: RefreshIndicator(
                    onRefresh: ()=> provider.fetchQnaList(),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h), // 하단 패딩을 추가하여 FAB가 가리지 않도록
                      children: [
                        // FAQ 섹션
                        _buildFaqSection(),

                        SizedBox(height: 24.h),

                        // 내 문의 목록 섹션
                        _buildMyInquiriesSection(),
                      ],
                    ),
                  )
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _navigateToNewInquiry,
                icon: Icon(Icons.add, size: 20.r),
                label: Text(
                  '문의하기',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            )
        );
      }
    );
  }

  // FAQ 섹션 위젯
  Widget _buildFaqSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // FAQ 헤더
          InkWell(
            onTap: () {
              setState(() {
                _isFaqExpanded = !_isFaqExpanded;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
              bottomLeft: _isFaqExpanded ? Radius.zero : Radius.circular(12.r),
              bottomRight: _isFaqExpanded ? Radius.zero : Radius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 22.r,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '자주 묻는 질문 (FAQ)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isFaqExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24.r,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // FAQ 내용 (접고 펼치기 가능)
          if (_isFaqExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.fs!.length,
              separatorBuilder: (context, index) => Divider(
                height: 1.h,
                thickness: 1.h,
                indent: 16.w,
                endIndent: 16.w,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                return _buildFaqItem(provider.fs![index]);
              },
            ),
        ],
      ),
    );
  }

  // FAQ 항목 위젯
  Widget _buildFaqItem(QnaModel faq) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      title: Text(
        faq.question,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      iconColor: Theme.of(context).colorScheme.primary,
      collapsedIconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        Text(
          faq.answer ?? '(알수없음)',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 내 문의 목록 섹션 위젯
  Widget _buildMyInquiriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 22.r,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              '나의 문의 내역',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 내 문의 목록
        provider.qs!.isEmpty
            ? _buildEmptyInquiries()
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.qs!.length,
          itemBuilder: (context, index) {
            return _buildInquiryItem(provider.qs![index]);
          },
        ),
      ],
    );
  }

  // 문의 내역 없음 위젯
  Widget _buildEmptyInquiries() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48.r,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          Text(
            '문의 내역이 없습니다',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '하단의 \'문의하기\' 버튼을 눌러 새 문의를 작성해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // 문의 항목 위젯
  Widget _buildInquiryItem(QnaModel inquiry) {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => _navigateToInquiryDetail(inquiry),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 행: 카테고리와 상태
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      inquiry.title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(inquiry.answer == null ? InquiryStatus.pending : InquiryStatus.answered),
                ],
              ),

              SizedBox(height: 10.h),

              // 제목
              Text(
                inquiry.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 6.h),

              // 내용 미리보기
              Text(
                inquiry.question,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 10.h),

              // 하단 행: 날짜와 화살표
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.r,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    dateFormat.format(inquiry.createAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14.r,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 문의 상태 배지 위젯
  Widget _buildStatusBadge(InquiryStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case InquiryStatus.pending:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        text = '접수중';
        break;
      case InquiryStatus.inProgress:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        text = '처리중';
        break;
      case InquiryStatus.answered:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        text = '답변완료';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// 문의 상태 열거형
enum InquiryStatus {
  pending,    // 접수중
  inProgress, // 처리중
  answered,   // 답변완료
}
