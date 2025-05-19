import 'package:my_sports_calendar/manager/auth/social/Google_Manager.dart';

import '../../../manager/project/Import_Manager.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
          GoogleManager().googleLogin();
      },
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xffffffff),
            borderRadius: BorderRadius.circular(10)
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        height: 50,
        child: Row(
          children: [
            Container(
              height: 35, width: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xffffffff),
                border: Border.all(color: Theme.of(context).highlightColor, width: 1)
              ),
              alignment: Alignment.center,
              child: Image.asset('assets/image/social/google.png', height: 30, width: 30,),
            ),
            Expanded(child: Center(child: Text('구글로 시작하기', style: TextStyle(fontSize: 14, color: const Color(0xff000000), fontWeight: FontWeight.w500),),))
          ],
        ),
      ),
    );
  }
}
