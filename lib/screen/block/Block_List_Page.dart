import 'package:my_sports_calendar/provider/friends/Block_Provider.dart';

import '../../manager/project/Import_Manager.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  late BlockProvider provider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      provider.fetchBlock();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<BlockProvider>(context);
    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '차단목록',
        ),
        body: provider.blockList.isEmpty ?
         Center(
           child: NadalEmptyList(title: '차단한 사용자가 없어요', subtitle: '사용자 프로필에서 차단이 가능해요',),
         ) :
        
        CustomScrollView(
          slivers: [
            SliverList.builder(
              itemCount: provider.blockList.length,
              itemBuilder: (context, index){
                final item = provider.blockList[index];
                return ListTile(
                  onTap: ()=> DialogManager.showBasicDialog(
                      title: '경고',
                      content: '차단을 해제할까요?',
                      confirmText: '네',onConfirm: (){
                        provider.cancelBlock(item['uid']);
                  },
                      cancelText: '아니오'
                  ),
                  contentPadding: EdgeInsetsGeometry.symmetric(vertical: 8.h, horizontal: 12.w),
                  leading: NadalProfileFrame(imageUrl: item['profileImage']),
                  title: Text(item['nickName'], style: Theme.of(context).textTheme.bodyMedium,),
                );
              }
            )
          ],
        ),
      ),
    );
  }
}
