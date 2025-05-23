import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/qna/Qna_Model.dart';

class QnaWriteProvider extends ChangeNotifier{
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;


  void submitQna(String title, String question) async {
    AppRoute.pushLoading();
    _isSubmitting = true;
    notifyListeners();
    bool success = false;
    QnaModel? qnaModel;
    try{
      final qna = {
        'title': title,
        'question': question,
      };

      final res = await serverManager.post('app/qna/create', data: qna);

      if(res.statusCode == 200){
        final Map<String, dynamic> data = res.data;
        qnaModel = QnaModel.fromJson(data);
        success = true;
      }
    }catch(e){
      print(e);
      DialogManager.warningHandler('문의 생성에 실패했습니다.');
    }finally{
       AppRoute.popLoading();
       _isSubmitting = false;
       notifyListeners();
       if(success && qnaModel != null){ //성공했다면
         AppRoute.context!.pop(qnaModel);
       }
    }
  }
}