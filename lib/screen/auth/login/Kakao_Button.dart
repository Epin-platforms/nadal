import '../../../manager/project/Import_Manager.dart';

class KakaoButton extends StatelessWidget {
  const KakaoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xfffde500),
          borderRadius: BorderRadius.circular(10)
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      height: 50,
      child: Row(
        children: [
          Container(
            height: 35, width: 35,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                    image: AssetImage('assets/image/social/kakao.png'),
                    fit: BoxFit.cover
                )
            ),
          ),
          Expanded(child: Center(child: Text('카카오로 시작하기', style: TextStyle(fontSize: 14, color: const Color(0xff000000), fontWeight: FontWeight.w500))))
        ],
      ),
    );
  }
}
