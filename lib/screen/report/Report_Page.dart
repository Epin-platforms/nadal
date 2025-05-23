import '../../manager/project/Import_Manager.dart';
import '../../model/report/Report_Model.dart';
import '../../provider/report/Report_Provider.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.targetId, required this.type});
  final String targetId;
  final TargetType type;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _commentController = TextEditingController();
  late ReportProvider provider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_)=> ReportProvider(),
        builder: (context, child){
          provider = Provider.of<ReportProvider>(context);
          return IosPopGesture(
            child: Scaffold(
              appBar: NadalAppbar(
                title: '신고하기',
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReasonSelection(),
                    SizedBox(height: 32.h),
                    _buildAdditionalComment(),
                    SizedBox(height: 40.h),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          );
        },
    );
  }


  Widget _buildReasonSelection() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        final reasons = provider.getApplicableReasons(widget.type);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 사유',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '해당하는 사유를 선택해주세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 16.h),
            ...reasons.map((reason) => _buildReasonTile(reason, provider)),
          ],
        );
      },
    );
  }

  Widget _buildReasonTile(ReportReason reason, ReportProvider provider) {
    final isSelected = provider.selectedReasonId == reason.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => provider.selectReason(reason.id),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Radio<String>(
                value: reason.id,
                groupValue: provider.selectedReasonId,
                onChanged: (value) => provider.selectReason(value),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      reason.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalComment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추가 설명 (선택사항)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '신고 사유에 대한 자세한 설명을 입력해주세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '구체적인 내용을 입력해주세요...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
          onChanged: (value) => provider.updateAdditionalComment(value),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<ReportProvider>(
      builder: (context, reportManager, child) {
        final canSubmit = provider.selectedReasonId != null;

        return SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: canSubmit && !provider.isSubmitting
                ? _handleSubmit
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSubmit
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              foregroundColor: canSubmit
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: provider.isSubmitting
                ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  canSubmit ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            )
                : Text(
              '신고하기',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getTargetIcon() {
    switch (widget.type) {
      case TargetType.chat:
        return Icons.chat_bubble_outline;
      case TargetType.schedule:
        return Icons.event_note_outlined;
      case TargetType.room:
        return Icons.meeting_room_outlined;
      case TargetType.user:
        return Icons.person_outline;
    }
  }

  Future<void> _handleSubmit() async {
    try {
      final success = await provider.submitReport(
        targetType: widget.type,
        targetId: widget.targetId
      );

      if (success && mounted) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );

        // 페이지 닫기
        context.pop();
      } else if (mounted) {
        // 실패 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
