import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/account/Account_Create_Provider.dart';
import 'package:my_sports_calendar/provider/account/Account_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Container.dart';

import '../../manager/project/Import_Manager.dart';

class AccountCreate extends StatelessWidget {
  const AccountCreate({super.key});

  @override
  Widget build(BuildContext context) {
    final accountProvider  = Provider.of<AccountProvider>(context);
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_)=> AccountCreateProvider(),
      builder: (context, child) {
        final provider = Provider.of<AccountCreateProvider>(context);
        return IosPopGesture(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: NadalAppbar(
                title: '계좌 등록',
              ),
              body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 40,),
                              Text('아래 내용을 입력 후\n등록 버튼을 눌러주세요', style: theme.textTheme.titleLarge),
                              SizedBox(height: 24,),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: InkWell(
                                      onTap: () async{
                                        final bank = await PickerManager.bankPicker();

                                        if(bank != null){
                                          provider.setBank(bank);
                                        }
                                      },
                                      child: NadalSolidContainer(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(provider.bank ?? '은행선택', style: theme.textTheme.bodyMedium,)),
                                            Icon(
                                              CupertinoIcons.chevron_down, size: 18,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8,),
                                  Expanded(child: NadalTextField(controller: provider.accountController, maxLength: 14, keyboardType: TextInputType.number, label: "계좌번호",)),
                                ],
                              ),
                              SizedBox(height: 16,),
                              NadalTextField(controller: provider.accountNameController, label: '예금주명', maxLength: 10,),
                              SizedBox(height: 24,),
                              Text('마지막이에요\n해당 계좌를 뭐라고 부를까요?', style: theme.textTheme.titleLarge),
                              SizedBox(height: 24,),
                              NadalTextField(controller: provider.titleController, label: '별명', maxLength: 10,),
                            ],
                          ),
                        ),
                      ),
                      NadalButton(isActive: true, title: '계좌 등록',
                          onPressed: () async{
                            final router = GoRouter.of(context);
                            final res = await provider.create();

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
