import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/auth/social/Kakao_Manager.dart';
import 'package:my_sports_calendar/model/share/Share_Parameter.dart';

import '../manager/project/Import_Manager.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key, required this.shareParameter});
  final ShareParameter shareParameter;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 바
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
        
            // 제목
            Text(
              '공유하기',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
        
            // 공유 옵션 그리드
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 0.9,
              children: [
                // 카카오톡 공유 옵션
                _buildShareOption(
                  context,
                  image: 'assets/image/social/kakao.png',
                  color: Color(0xFFFEE500),
                  label: '카카오톡',
                  onTap: () {
                    // 카카오톡 공유 로직
                    KakaoManager().sendKakaoInviteForm(shareParameter);
                    Navigator.pop(context);
                  },
                ),
        
             /*   // 다른 공유 옵션들 (주석 처리된 형태)
                _buildShareOption(
                  context,
                  icon: BootstrapIcons.instagram,
                  color: Colors.grey.shade400,
                  label: 'Instagram',
                  onTap: null,
                  isDisabled: true,
                ),
                _buildShareOption(
                  context,
                  icon: BootstrapIcons.facebook,
                  color: Colors.grey.shade400,
                  label: 'Facebook',
                  onTap: null,
                  isDisabled: true,
                ),
                _buildShareOption(
                  context,
                  icon: BootstrapIcons.twitter,
                  color: Colors.grey.shade400,
                  label: 'Twitter',
                  onTap: null,
                  isDisabled: true,
                ),*/
              ],
            ),
        
            SizedBox(height: 24.h),
        
            // 링크 복사 버튼
            if(shareParameter.link != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // 링크 복사 로직
                  Clipboard.setData(ClipboardData(text: shareParameter.link!));
                  Navigator.pop(context);
                },
                icon: Icon(Icons.link, size: 18.sp),
                label: Text('링크 복사'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
        
            SizedBox(height: 16.h),
        
            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text('닫기', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        IconData? icon,
        String? image,
        required Color color,
        required String label,
        required VoidCallback? onTap,
        bool isDisabled = false,
      }) {
    final theme = Theme.of(context);
    final opacity = isDisabled ? 0.5 : 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha:isDisabled ? 0.3 : 0.9),
              shape: BoxShape.circle,
              image: image != null ? DecorationImage(image: AssetImage(image), fit: BoxFit.cover) : null
            ),
            child:
            icon != null ?
            Icon(
              icon,
              color: isDisabled ? Colors.grey.shade600 : Colors.white,
              size: 24.r,
            ) : null
            ,
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:opacity),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}