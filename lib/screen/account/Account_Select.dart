import '../../manager/project/Import_Manager.dart';

class AccountSelect extends StatelessWidget {
  const AccountSelect({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AccountProvider>(context);
    final theme = Theme.of(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '계좌선택',
            actions: [
              NadalIconButton(
                  onTap: ()=> context.push('/create/account'),
                  icon: Icons.add_box_outlined,
              )
            ],
          ),
          body: SafeArea(
              child: provider.accounts == null ?
                  Container() :
                  provider.accounts!.isEmpty ?
                  NadalEmptyList(
                      title: '등록한 계좌가 없어요',
                      subtitle: '지금 계좌를 등록할까요?',
                      actionText: '계좌 등록하기',
                      onAction: (){
                        context.push('/create/account');
                      },
                  ) :
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24,),
                        Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text('스케줄 진행에 사용할 계좌를\n선택해주세요', style: theme.textTheme.titleLarge,)),
                        SizedBox(height: 24,),
                        ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: provider.accounts!.length,
                            itemBuilder: (context, index){
                              final item = provider.accounts![index];
                              return ListTile(
                                onTap: (){
                                  context.pop(item);
                                },
                                leading: Image.asset(ListPackage.banks[item['bank']]!['logo'], height: 45, width: 45, fit: BoxFit.cover,),
                                title: Text(item['accountTitle'], style: theme.textTheme.titleMedium),
                                subtitle: Text(item['account'], style: theme.textTheme.labelLarge,),
                              );
                            }
                        ),

                      ],
                    ),
                  )
          ),
        )
    );
  }
}
