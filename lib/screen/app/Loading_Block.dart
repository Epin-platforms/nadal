import 'package:my_sports_calendar/screen/splash/widget/Bounce_Widget.dart';

import '../../manager/project/Import_Manager.dart';

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> context.pop(),
      child: PopScope(
        canPop: false,
        child: Material(
          type: MaterialType.transparency,
          color: Theme.of(context).highlightColor.withValues(alpha: 0.2),
          child: Center(
            child: BounceWidget(amplitude: 50,child: Image.asset('assets/image/app/splash_icon.png', height: 60, width: 60, fit: BoxFit.cover,),),
          ),
        ),
      ),
    );
  }
}
