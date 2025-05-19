import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class AccountProvider extends ChangeNotifier{
  AccountProvider(){
    _fetchAccounts();
  }

  List<Map>? _accounts;
  List<Map>? get accounts => _accounts;

  void get fetchAccounts => _fetchAccounts();

  void _fetchAccounts() async{
    final res = await serverManager.get('user/account');
    if(res.statusCode == 200){
      _accounts = List.from(res.data);
      notifyListeners();
    }
  }


}