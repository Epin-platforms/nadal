import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
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

  updateRecently(QnaModel qnaModel){
    _qs!.insert(0, qnaModel);
    notifyListeners();
  }
  
  
  removeQna(int qid) async{
    _qs!.removeWhere((e)=> e.qid == qid);
    notifyListeners();
    try{
      await serverManager.delete('app/qna/delete', data: {'qid' : qid});
      DialogManager.showBasicDialog(title: '문의가 삭제되었습니다', content: '언제든 궁금한점이 있다면 문의해주세요', confirmText: '확인');
    }catch(err){
      DialogManager.showBasicDialog(title: '문의 삭제에 실패했습니다', content: '나중에 다시 시도해주세요', confirmText: '확인');
    }
  }
}