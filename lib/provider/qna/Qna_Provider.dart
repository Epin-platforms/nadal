import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/qna/Qna_Model.dart';

class QnaProvider extends ChangeNotifier{
  List<QnaModel>? _qs;
  List<QnaModel>? get qs => _qs;

  List<QnaModel>? _fs;
  List<QnaModel>? get fs => _fs;

  Future<void> fetchQnaList() async{
    final res = await serverManager.get('app/qna');
    if(res.statusCode == 200){
      _qs = List<QnaModel>.from(res.data.map((e)=> QnaModel.fromJson(e)));
    }
    await fetchFaqList();
  }

  fetchFaqList() async{
    final res = await serverManager.get('app/faq');

    if(res.statusCode == 200){
      _fs = List<QnaModel>.from(res.data.map((e)=> QnaModel.fromJson(e)));
    }else{
      _fs = [];
    }
    notifyListeners();
  }
}