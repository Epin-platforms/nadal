import 'package:bootstrap_icons/bootstrap_icons.dart';

import '../../../manager/project/Import_Manager.dart';

class MyProfileMenu extends StatelessWidget {
  const MyProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: (){
              context.push('/myProfile/profileEdit');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 80,
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.pencil_fill, size: 24, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12,),
                  Text('프로필 편집', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),)
                ],
              ),
            ),
          ),
          SizedBox(width: 16,),
          InkWell(
            onTap: (){
              context.push('/myProfile/affiliationEdit');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 80,
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.house_gear_fill, size: 24, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12,),
                  Text('대표클럽 설정', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400))
                ],
              ),
            ),
          ),
          SizedBox(width: 16,),
          InkWell(
            onTap: (){
              context.push('/myProfile/kakaoConnect');
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 80,
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(BootstrapIcons.patch_check_fill, size: 24, color: Theme.of(context).colorScheme.onSurface,),
                  SizedBox(height: 12,),
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
