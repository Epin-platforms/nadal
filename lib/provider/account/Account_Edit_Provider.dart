import 'package:flutter/material.dart';

import '../../manager/dialog/Dialog_Manager.dart';
import '../../manager/server/Server_Manager.dart';
import '../../routes/App_Routes.dart';

class AccountEditProvider extends ChangeNotifier {
  late final String? _originTitle;
  late final String? _originAccountNumber;
  late final String? _originAccountName;
  late final String? _originBank;
  late final int _accountId;

  AccountEditProvider(String? bank, String? title, String? accountNumber, String? accountName, int id){
    _originTitle = title;
    _originBank = bank;
    _originAccountName = accountName;
    _originAccountNumber = accountNumber;
    _accountId = id;
    _titleController = TextEditingController();
    _accountController = TextEditingController();
    _accountNameController = TextEditingController();
  }

  setText(){
    _titleController.text = _originTitle ?? '';
    _accountController.text = _originAccountNumber ?? '';
    _accountNameController.text = _originAccountName ?? '';
    _bank = _originBank;
    notifyListeners();
  }


  late TextEditingController _titleController;
  late TextEditingController _accountController;
  late TextEditingController _accountNameController;

  String? _bank;

  TextEditingController get titleController => _titleController;
  TextEditingController get accountController => _accountController;
  TextEditingController get accountNameController => _accountNameController;

  String? get bank => _bank;

  setBank(String bank){
    _bank = bank;
    notifyListeners();
  }


  Future edit() async{
    if(accountNameController.text.isEmpty || accountNameController.text.length > 10){
      DialogManager.warningHandler('흠.. 예금주명이 이상해요 🤔');
      return;
    }

    if(accountController.text.length < 10 || accountController.text.length > 14){
      DialogManager.warningHandler('흠.. 계좌번호가 이상해요 🤔');
      return;
    }

    if(_bank == null){
      DialogManager.warningHandler('흠.. 은행이 이상해요 🤔');
      return;
    }

    if(titleController.text.length > 10){
      DialogManager.warningHandler('흠.. 별명이 이상해요 🤔');
      return;
    }

    return await startEdit();
  }

  Future<int> startEdit() async{
    int statusCode = 0;
    AppRoute.pushLoading();
    try{
      final res = await serverManager.put('user/account-update', data: _toMap());

      statusCode = res.statusCode ?? 404;
    }finally{
      AppRoute.popLoading();
    }

    return statusCode;
  }


  Map<String, dynamic> _toMap(){
    Map<String, dynamic> map = {
      'accountId' : _accountId
    };

    final title = titleController.text.trim().isEmpty ?
    '$bank계좌${accountController.text.substring(0, 4)}'
        : titleController.text.trim();

    if(_originTitle != title){
      map.addAll({'accountTitle': title});
    }

    if(_originAccountNumber != accountController.text.trim()){
      map.addAll({'account' : accountController.text.trim()});
    }

    if(_originAccountName != accountNameController.text.trim()){
      map.addAll({'accountName' : accountNameController.text.trim()});
    }

    if(_originBank != _bank){
      map.addAll({'bank' : _bank});
    }

    print(map);
    return map;
  }
}
