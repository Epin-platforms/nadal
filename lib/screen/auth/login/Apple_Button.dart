import 'package:my_sports_calendar/manager/auth/social/Apple_Manager.dart';

import '../../../manager/project/Import_Manager.dart';

class AppleButton extends StatelessWidget {
  const AppleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
          AppleManager().appleLogin();
      },
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xff000000),
            border: Border.all(color: const Color(0xffdddddd)),
            borderRadius: BorderRadius.circular(10)
        ),
        padding: EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        child: Row(
          children: [
            Container(
              height: 35, width: 35,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000000),
              ),
              alignment: Alignment.center,
              child: Image.asset('assets/image/social/apple.png', height: 30, width: 30, color: const Color(0xffffffff),),
            ),
            Expanded(child: Center(child: Text('애플로 시작하기', style: TextStyle(fontSize: 14, color: const Color(0xffffffff), fontWeight: FontWeight.w500),),))
          ],
        ),
      ),
    );
  }
}
