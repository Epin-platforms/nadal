import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/form/widget/Text_Form_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class FriendsProvider extends ChangeNotifier{
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> get friends => _friends;


  getFriends() async{
    final response = await serverManager.get('user/friends');

    if(response.statusCode == 200){
      _friends = List.from(response.data);
      _friends.sort((a, b) => TextFormManager.compareKorean(a['nickName'], b['nickName']));
      notifyListeners();
    }
  }

}