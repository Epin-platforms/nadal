import '../../../manager/project/Import_Manager.dart';

class VerificationButton extends StatelessWidget {
  const VerificationButton({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFEE500), // 카카오 노랑
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
      ),
      onPressed: () {
        registerProvider.connectKakao();
      },
      icon: Image.asset(
        'assets/image/social/kakao_icon.png', // 카카오 아이콘 경로
        width: 20,
        height: 20,
      ),
      label: const Text(
        '카카오로 본인 정보 불러오기',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );

  }
}
