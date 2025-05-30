import 'package:my_sports_calendar/widget/Nadal_Dot.dart';

import '../../../../../manager/project/Import_Manager.dart';

class InformationBox extends StatelessWidget {
  const InformationBox({super.key, required this.isLeader});
  final bool isLeader;
  @override
  Widget build(BuildContext context) {
    final List<String> information = isLeader ? ['순서를 바꾸고 싶다면, 카드를 꾹 눌러봐요!.', '변경 후 \'순서 공개\'를 눌러야 적용돼요.'] : ['순서를 정하는 중이에요, 조금만 기다려주세요~'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: information.map((msg) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NadalDot(color: Theme.of(context).colorScheme.secondary,),
              SizedBox(width: 4.w,),
              Expanded(child: Text(msg, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 13.sp))),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
