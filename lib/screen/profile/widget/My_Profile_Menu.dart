import 'package:bootstrap_icons/bootstrap_icons.dart';

import '../../../manager/project/Import_Manager.dart';

class MyProfileMenu extends StatelessWidget {
  const MyProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 88.r;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: (){
              context.push('/profileEdit');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: size,
              width: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.pencil_fill, size: 24.r, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12.h,),
                  Text('프로필 편집', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),)
                ],
              ),
            ),
          ),
          SizedBox(width: 16.w,),
          InkWell(
            onTap: (){
              context.push('/affiliationEdit');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: size,
              width: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.house_gear_fill, size: 24.r, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12.h,),
                  Text('대표클럽 설정', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400))
                ],
              ),
            ),
          ),
          SizedBox(width: 16.w,),
          InkWell(
            onTap: (){
              context.push('/kakaoConnect');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: size,
              width: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.patch_check_fill, size: 24.r, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12.h,),
                  Text('카카오 연결', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
