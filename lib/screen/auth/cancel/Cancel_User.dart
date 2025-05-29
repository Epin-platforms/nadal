import 'package:my_sports_calendar/provider/auth/Cancel_Provider.dart';

import '../../../manager/project/Import_Manager.dart';

class CancelUser extends StatelessWidget {
  const CancelUser({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    return ChangeNotifierProvider(
      create: (_)=> CancelProvider(),
      builder: (context, child) {
        final provider = Provider.of<CancelProvider>(context);
        return IosPopGesture(
          child: Scaffold(
            appBar: NadalAppbar(
              title: '회원탈퇴',
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 경고 카드
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: errorColor,
                                  size: 20.w,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '탈퇴 전 꼭 확인해주세요!',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: errorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _buildWarningItem(
                              theme,
                              '탈퇴 시 모든 개인정보 및 활동 기록이 삭제되며, 복구가 불가능합니다.',
                            ),
                            SizedBox(height: 8.h),
                            _buildWarningItem(
                              theme,
                              '진행 중인 게임이나 운영중인 방이 있는 경우 탈퇴가 제한될 수 있습니다.',
                            ),
                            SizedBox(height: 8.h),
                            _buildWarningItem(
                              theme,
                              '동일한 연락처와 이메일로 재가입 시 이전 정보는 연동되지 않습니다.',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      Text(
                        '탈퇴 사유를 알려주세요',
                        style: theme.textTheme.titleLarge,
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        '더 나은 서비스 개선을 위해 소중한 의견을 남겨주세요.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // 탈퇴 사유 리스트
                      _buildReasonsList(context, provider, theme),

                      SizedBox(height: 32.h),

                      // 동의 체크박스
                      InkWell(
                        onTap: () {
                          provider.toggleAgreement();
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: Checkbox(
                                  value: provider.isAgreed,
                                  onChanged: (_) {
                                    provider.toggleAgreement();
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  '위 내용을 모두 확인했으며, 회원탈퇴에 동의합니다.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // 탈퇴 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.canWithdraw
                              ? () {
                            // 여기서 탈퇴 로직 실행 (프로바이더에서 처리 예정)
                            _showWithdrawalConfirmDialog(context, provider);
                          }
                           : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: theme.disabledColor,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            '회원 탈퇴하기',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }


  // 경고 아이템 위젯
  Widget _buildWarningItem(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.error,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // 탈퇴 사유 리스트 위젯
  Widget _buildReasonsList(
      BuildContext context,
      CancelProvider provider,
      ThemeData theme,
      ) {
    return Column(
      children: provider.reasons.map((reason) {
        final isOtherReason = reason.id == '7'; // '기타' 항목

        return Column(
          children: [
            InkWell(
              onTap: () {
                provider.toggleReason(reason.id);
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: Checkbox(
                        value: reason.isSelected,
                        onChanged: (_) {
                          provider.toggleReason(reason.id);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      reason.text,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // '기타' 선택 시 텍스트 필드 표시
            if (isOtherReason && reason.isSelected)
              Padding(
                padding: EdgeInsets.only(left: 36.w, top: 4.h, bottom: 8.h),
                child: TextField(
                  onChanged: provider.updateOtherReason,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: '탈퇴 사유를 직접 입력해주세요',
                    contentPadding: EdgeInsets.all(12.w),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            if (reason.id != provider.reasons.last.id)
              Divider(height: 1.h),
          ],
        );
      }).toList(),
    );
  }

  // 탈퇴 확인 다이얼로그
  Future<void> _showWithdrawalConfirmDialog(BuildContext context, CancelProvider provider) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '정말 탈퇴하시겠습니까?',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            '회원 탈퇴 시 모든 데이터가 삭제되며 복구가 불가능합니다.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async{
                Navigator.of(context).pop();
                final result = await provider.withdrawMembership();
                if(result == true){
                  context.go('/login?reset=true');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(
                '탈퇴하기',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
