import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../manager/project/Import_Manager.dart';

class ProfileMore extends StatefulWidget {
  const ProfileMore({super.key});

  @override
  State<ProfileMore> createState() => _ProfileMoreState();
}

class _ProfileMoreState extends State<ProfileMore> {
  late AppProvider appProvider;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      appProvider.getTotalCacheSize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final provider = Provider.of<UserProvider>(context);
    appProvider = Provider.of<AppProvider>(context);
    final user = provider.user!;
    return Scaffold(
      appBar: NadalAppbar(
        title: '개인 설정',
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () async{
              showCupertinoModalPopup(context: context,
                  builder: (context){
                    final nav = Navigator.of(context);
                    return NadalSheet(actions: [
                      CupertinoActionSheetAction(
                          onPressed: (){
                              nav.pop();
                              context.read<AppProvider>().setTheme('dark');
                          },
                          child: Text('다크모드', style: Theme.of(context).textTheme.bodyLarge,)
                      ),
                      CupertinoActionSheetAction(
                          onPressed: (){
                            nav.pop();
                            context.read<AppProvider>().setTheme('light');
                          },
                          child: Text('라이트모드', style: Theme.of(context).textTheme.bodyLarge,)
                      ),
                      CupertinoActionSheetAction(
                          onPressed: (){
                            nav.pop();
                            context.read<AppProvider>().setTheme('system');
                          },
                          child: Text('시스템', style: Theme.of(context).textTheme.bodyLarge,)
                      )
                    ]);
                  });
            },
            leading: Icon(BootstrapIcons.brush, size: 24,),
            title: Text('테마', style: titleStyle),
          ),
          Divider(height: 0.5,),
          ListTile(
            onTap: () {
                DialogManager.showBasicDialog(
                    title: '저장된 캐시를 삭제할까요?',
                    content: '삭제시 불러오기가 느려질수 있어요\n삭제해도 앱 사용에는 문제가 없어요.',
                    confirmText: '취소',
                    cancelText: '삭제하기',
                    onCancel: () async{
                      try{
                        await DefaultCacheManager().emptyCache(); // 캐시 비우기
                        await appProvider.getTotalCacheSize();
                        SnackBarManager.showCleanSnackBar(context, '삭제가 완료되었습니다.\n삭제 불가능한 캐시가 남아있을 수 있습니다');
                      }catch(e){
                        print(e);
                      }
                    }
                );
            },
            leading: Icon(BootstrapIcons.clipboard_data, size: 24,),
            title: Text('저장공간', style: titleStyle,),
            trailing: Text('사용량: ${appProvider.cacheSize.toStringAsFixed(2)} MB', style: Theme.of(context).textTheme.labelSmall)
          ),
          Divider(height: 0.5,),
          ListTile(
            onTap: ()=> showLicensePage(context: context),
            leading: Icon(BootstrapIcons.file_earmark_code, size: 24,),
            title: Text('오픈소스', style: titleStyle),
          ),
          Divider(),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Text('사용자 설정', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            onTap: (){
              DialogManager.showBasicDialog(title: '로그아웃하시겠어요?',
                  content: '잠깐 쉬는 거죠? 곧 다시 만나요!',
                  confirmText: '아니요, 계속 쓸래요',
                  cancelText: '네, 로그아웃할게요',
                  onCancel: (){
                      provider.logout(false, true);
                  });
            },
            leading: Icon(Icons.logout , size: 24,),
            title: Text('로그아웃', style: titleStyle),
          ),
          Divider(),
          ListTile(
            onTap: ()=> context.push('/cancel'),
            leading: Icon(BootstrapIcons.person_dash , size: 24,),
            title: Text('회원탈퇴', style: titleStyle),
          ),
        ],
      ),
    );
  }
}
