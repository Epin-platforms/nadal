import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/provider/account/Account_Provider.dart';

class AccountCreateProvider extends ChangeNotifier{

  AccountCreateProvider(){
    _titleController = TextEditingController();
    _accountController = TextEditingController();
    _accountNameController = TextEditingController();
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


  Future create() async{
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

    return await startCreate();
  }

  Future<int> startCreate() async{
    int statusCode = 0;
    AppRoute.pushLoading();
    try{
      final res = await serverManager.post('user/account/create', data: _toMap());

      statusCode = res.statusCode ?? 404;
    }finally{
      AppRoute.popLoading();
    }

    return statusCode;
  }


  Map<String, dynamic> _toMap(){
    final title = titleController.text.trim().isEmpty ?
        '$bank계좌${accountController.text.substring(0, 4)}'
        : titleController.text.trim();

    return {
      'bank' : _bank,
      'account' : accountController.text,
      'accountName' : accountNameController.text.trim(),
      'accountTitle' : title,
    };
  }
}