import 'package:flutter/cupertino.dart';
import '../../manager/project/Import_Manager.dart';

class ProfileMore extends StatelessWidget {
  const ProfileMore({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final provider = Provider.of<UserProvider>(context);
    final user = provider.user!;
    return Scaffold(
      appBar: NadalAppbar(
        title: '개인 설정',
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: ()=> context.push('/myProfile'),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            leading: NadalProfileFrame(imageUrl: user['profileImage'],),
            title: Text(user['name'],  style: Theme.of(context).textTheme.titleMedium,),
            subtitle: user['roomName'] == null ? null : Text(user['roomName'],  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),),
            trailing: SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NadalLevelFrame(level: user['level']),
                  Icon(CupertinoIcons.forward, size: 20, color: Theme.of(context).hintColor)
                ],
              ),
            ),
          ),
          Divider(height: 0.5),
          ListTile(
            onTap: () async{

            },
            leading: Icon(BootstrapIcons.brush, size: 24,),
            title: Text('테마', style: titleStyle),
          ),
          Divider(height: 0.5,),
          ListTile(
            onTap: () async{
            },
            leading: Icon(BootstrapIcons.clipboard_data, size: 24,),
            title: Text('저장공간', style: titleStyle,),
          ),
          Divider(height: 0.5,),
          ListTile(
            onTap: () async{

            },
            leading: Icon(BootstrapIcons.info_circle),
            title: Text('앱 관리', style: titleStyle),
            subtitle: Text('${context.read<AppProvider>().appVersion} 버전', style: Theme.of(context).textTheme.labelMedium,)
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
                      provider.logout(false);
                  });
            },
            leading: Icon(Icons.logout , size: 24,),
            title: Text('로그아웃', style: titleStyle),
          ),
          Divider(),
          ListTile(
            onTap: ()=> showLicensePage(context: context),
            leading: Icon(BootstrapIcons.person_dash , size: 24,),
            title: Text('회원탈퇴', style: titleStyle),
          ),
        ],
      ),
    );
  }


}
