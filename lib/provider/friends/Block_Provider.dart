import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class BlockProvider extends ChangeNotifier{
  List<Map<String, dynamic>> _blockList = [];
  List<Map<String, dynamic>> get blockList => _blockList;

  void fetchBlock() async{
     final res = await serverManager.get('/user/get-block');

     _blockList.clear();
     if(res.statusCode == 200){
       _blockList = List<Map<String, dynamic>>.from(res.data);
       notifyListeners();
     }
  }
  
  void cancelBlock(String uid) async{
    final res  = await serverManager.delete('/user/cancel-block', data: {'blocked_uid' : uid});
    
    if(res.statusCode != 404 || res.statusCode != 500){
      _blockList.removeWhere((e)=> e['uid'] == uid);
      notifyListeners();
    }
  }
  
  void createBlock(String uid) async{
    final res = await serverManager.post('/user/block-user', data: { 'blocked_uid' : uid });
    
    if(res.statusCode == 200){
      fetchBlock();
    }
  }
}