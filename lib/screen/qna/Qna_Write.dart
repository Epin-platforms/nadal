import 'package:my_sports_calendar/provider/qna/Qna_Write_Provider.dart';

import '../../manager/project/Import_Manager.dart';
import '../../model/qna/Qna_Model.dart';
import '../../provider/qna/Qna_Provider.dart';

class QnaWrite extends StatefulWidget {
  const QnaWrite({super.key});

  @override
  State<QnaWrite> createState() => _QnaWriteState();
}

class _QnaWriteState extends State<QnaWrite> {
  late QnaWriteProvider provider;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  bool _isSubmitting = false;

  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_)=> QnaWriteProvider(),
      builder: (context, child) {
        provider = Provider.of<QnaWriteProvider>(context);
        return IosPopGesture(child: Scaffold(
          appBar: NadalAppbar(
            title: '문의 작성',
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '무엇을 도와드릴까요?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '문의하신 내용은 검토 후 빠른 시일 내에 답변 드리겠습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 24.h),
                    _buildTitleField(context),
                      SizedBox(height: 16.h),
                    _buildQuestionField(context),
                    Spacer(),
                    _buildSubmitButton(context),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '문의 제목을 입력해주세요',
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '제목을 입력해주세요';
            }
            if (value.length > 100) {
              return '제목은 100자 이내로 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuestionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '문의 내용',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _questionController,
          decoration: InputDecoration(
            hintText: '문의하실 내용을 자세히 적어주세요',
            filled: true,
            contentPadding: EdgeInsets.all(16.r),
          ),
          minLines: 6,
          maxLines: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '문의 내용을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: (){
          if(provider.isSubmitting) return;
          if (!_formKey.currentState!.validate()) return;
          provider.submitQna(_titleController.text, _questionController.text);
        },
        child: _isSubmitting
            ? SizedBox(
          height: 24.r,
          width: 24.r,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.r,
          ),
        )
            : Text('문의하기'),
      ),
    );
  }
}
