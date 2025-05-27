import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/account/Account_Edit_Provider.dart';

import '../../manager/project/Import_Manager.dart';

class AccountEdit extends StatefulWidget {
  const AccountEdit({super.key, required this.accountId});
  final int accountId;
  @override
  State<AccountEdit> createState() => _AccountEditState();
}

class _AccountEditState extends State<AccountEdit> {
  late AccountEditProvider provider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.accountId == -1){
        context.pop();
        DialogManager.showBasicDialog(title: '올바르지 않은 접근입니다.', content: '잠시후 다시 이용해주세요', confirmText: '확인');
      }else{
        provider.setText();
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider  = Provider.of<AccountProvider>(context);
    final account = accountProvider.accounts?.where((e)=> e['accountId'] == widget.accountId).firstOrNull;
    return ChangeNotifierProvider(
      create: (_)=> AccountEditProvider(account?['bank'] ,account?['accountTitle'], account?['account'], account?['accountName'], widget.accountId),
      builder: (context, child) {
        provider = Provider.of<AccountEditProvider>(context);
        return IosPopGesture(
            child: Scaffold(
              appBar: NadalAppbar(
                title: '계좌 수정',
              ),
              body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 40.h,),
                                Text('아래 내용을 입력 후\n등록 버튼을 눌러주세요', style: theme.textTheme.titleLarge),
                                SizedBox(height: 24.h,),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 100.w,
                                      child: InkWell(
                                        onTap: () async{
                                          final bank = await PickerManager.bankPicker();

                                          if(bank != null){
                                            provider.setBank(bank);
                                          }
                                        },
                                        child: NadalSolidContainer(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text(provider.bank ?? '은행선택', style: theme.textTheme.bodyMedium,)),
                                              Icon(
                                                CupertinoIcons.chevron_down, size: 18.r,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w,),
                                    Expanded(child: NadalTextField(controller: provider.accountController, maxLength: 14, keyboardType: TextInputType.number, label: "계좌번호",)),
                                  ],
                                ),
                                SizedBox(height: 16.h,),
                                NadalTextField(controller: provider.accountNameController, label: '예금주명', maxLength: 10,),
                                SizedBox(height: 24.h,),
                                Text('마지막이에요\n해당 계좌를 뭐라고 부를까요?', style: theme.textTheme.titleLarge),
                                SizedBox(height: 24.h,),
                                NadalTextField(controller: provider.titleController, label: '별명', maxLength: 10,),
                              ],
                            ),
                          ),
                        ),
                      ),
                      NadalButton(isActive: true, title: '계좌 수정',
                          onPressed: () async{
                            final router = GoRouter.of(context);
                            final res = await provider.edit();

                            if(res == 200){
                              accountProvider.fetchAccounts;
                              router.pop();
                            }else if(res == 409){
                              DialogManager.errorHandler('동일한 계좌가 이미 등록되어있어요');
                            }
                          }
                      )
                    ],
                  )
              ),
            )
        );
      }
    );
  }
}
