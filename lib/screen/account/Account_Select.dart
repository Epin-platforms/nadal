import 'package:flutter/cupertino.dart';

import '../../manager/project/Import_Manager.dart';

class AccountSelect extends StatefulWidget {
  const AccountSelect({super.key, required this.selectable});
  final bool selectable;

  @override
  State<AccountSelect> createState() => _AccountSelectState();
}

class _AccountSelectState extends State<AccountSelect> {
  late AccountProvider provider;

  void _option(theme, int accountId) {
    showCupertinoModalPopup(
        context: context,
        builder: (context){
          final nav = Navigator.of(context);
          return NadalSheet(actions: [
            CupertinoActionSheetAction(onPressed: (){
              nav.pop();
              context.push('/update/account?accountId=$accountId');
            }, child: Text('수정', style: theme.textTheme.bodyLarge?.copyWith(color: theme.secondaryHeaderColor),)),
            CupertinoActionSheetAction(onPressed: (){
              nav.pop();
              DialogManager.showBasicDialog(title: '정말 해당 계좌를 삭제할까요?', content: "삭제후 복구가 불가합니다",
                  confirmText: "앗! 잠깐만요",
                  cancelText: "삭제할레요",  onCancel: () async{
                    final res = await provider.removeAccount(accountId);
                    if(res != null){
                      SnackBarManager.showCleanSnackBar(context, '성공적으로 제거되었습니다');
                    }
                  });
            }, child: Text('삭제', style: theme.textTheme.bodyLarge,)),
          ]);
        }
    );
  }


  void _routeCreate(){
    if((provider.accounts?.length ?? 0) >= 5){
      DialogManager.showBasicDialog(title: '보유 계좌 갯수가 너무 많습니다', content: '1인당 최대 5개의 계좌를 생성할 수 있습니다', confirmText: '알겠어요');
    }else if(context.read<UserProvider>().user?['verificationCode'] == null){
      DialogManager.showBasicDialog(title: '앗! 이런', content: "계좌는 본인 인증을 한 사용자만 가능해요",
          cancelText: '괜찮아요',
          onConfirm: (){
            context.push('/kakaoConnect');
          },
          confirmText: '본인인증 하기');
    }else{
      context.push('/create/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<AccountProvider>(context);
    final theme = Theme.of(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: widget.selectable ? '계좌선택' : '마이계좌',
            actions: [
              NadalIconButton(
                  onTap: (){
                    _routeCreate();
                  },
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
                        _routeCreate();
                      },
                  ) :
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h,),
                        if(widget.selectable)
                          ...[
                            Padding(
                                padding: EdgeInsets.only(left: 16.w),
                                child: Text('스케줄 진행에 사용할 계좌를\n선택해주세요', style: theme.textTheme.titleLarge,)),
                            SizedBox(height: 24.h,),
                          ],
                        ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: provider.accounts!.length,
                            itemBuilder: (context, index){
                              final item = provider.accounts![index];
                              return ListTile(
                                onTap: (){
                                  if(widget.selectable){
                                    context.pop(item);
                                  }else{
                                    _option(theme, item['accountId']);
                                  }
                                },
                                contentPadding: EdgeInsets.only(left: 16.w, right: 8.w, top: 8.h, bottom: 8.h),
                                leading: Image.asset(ListPackage.banks[item['bank']]!['logo'], height: 45.r, width: 45.r, fit: BoxFit.cover,),
                                title: Text(item['accountTitle'], style: theme.textTheme.titleMedium),
                                subtitle: Text(item['account'], style: theme.textTheme.labelLarge,),
                                trailing: IconButton(
                                    onPressed: (){
                                      _option(theme, item['accountId']);
                                    },
                                    icon: Icon(BootstrapIcons.three_dots_vertical, size: 24.r,)
                                ),
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
