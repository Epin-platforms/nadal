import '../../../manager/project/Import_Manager.dart';

class VerificationButton extends StatelessWidget {
  const VerificationButton({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEE500), // 카카오 노랑
            foregroundColor: Colors.black,
            minimumSize: Size.fromHeight(48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 1,
          ),
          onPressed: provider.loading ? null : () {
            print('카카오 본인정보 불러오기 버튼 클릭');
            provider.connectKakao();
          },
          icon: provider.loading
              ? SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
              : Image.asset(
            'assets/image/social/kakao_icon.png',
            width: 20.r,
            height: 20.r,
          ),
          label: Text(
            provider.loading ? '정보 불러오는 중...' : '카카오로 본인 정보 불러오기',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp
            ),
          ),
        );
      },
    );
  }
}