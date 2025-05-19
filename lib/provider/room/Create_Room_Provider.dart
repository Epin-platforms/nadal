import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/form/room/Tag_Form_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class CreateRoomProvider extends ChangeNotifier{
  CreateRoomProvider(String local, String city){
    _local = local;
    _city = city;
    _roomNameController = TextEditingController();
    _tagController = TextEditingController(text: '#');
    _enterCodeController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  String get local => _local;
  String get city => _city;

  TextEditingController get roomNameController => _roomNameController;
  TextEditingController get tagController => _tagController;
  TextEditingController get enterCodeController => _enterCodeController;
  TextEditingController get descriptionController => _descriptionController;

  bool get useNickname => _useNickname;
  bool get useEnterCode => _useEnterCode;

  List<String> get tags => _tags;
  //지역 선택
  String _local = '';
  String _city = '';

  //채팅 방이름 입력
  late TextEditingController _roomNameController;

  //익명 사용여부
  bool _useNickname = true;

  //채팅방 태그들
  List<String> _tags = [];
  late TextEditingController _tagController;

  //입장 패스워드
  bool _useEnterCode = true;
  late TextEditingController _enterCodeController;

  //방소개
  late TextEditingController _descriptionController;


  setCity(String value){
    if(value != _city){
      _city = value;
      notifyListeners();
    }
  }

  setLocal(String value){
    if(value != _local){
      if(_city.isNotEmpty){
        _city = '';
      }
      _local = value;
      notifyListeners();
    }
  }

  setUseNickname(bool value){
    if(value != _useNickname){
      _useNickname = value;
      notifyListeners();
    }
  }

  setUseEnterCode(bool value){
    if(value != _useEnterCode){
      _useEnterCode = value;
      notifyListeners();
    }
  }

  setTag(String value){
    final val = value.trim();
    if(val.endsWith(',')){
      var tag = val.replaceRange(value.length - 1, null, '').replaceAll('#', '');

      if(tag.isEmpty){
        DialogManager.showBasicDialog(title: '앗! 태그가 이상해요', content: '\',(쉼표)\'로 태그를 구분해주세요', confirmText: '확인');
        _tagController.text = '#';
        notifyListeners();
        return;
      }

      _tags.add('#$tag');
      _tagController.text = '#';
      notifyListeners();
    }
  }

  removeTag(int index){
    _tags.removeAt(index);
    notifyListeners();
  }

  void createRoom() async{
    if(_roomNameController.text.isEmpty || _roomNameController.text.length > 30){
      _warningHandler('흠.. 클럽명이 이상해요 🤔');
      return;
    }else if(city.isEmpty){
      _warningHandler('흠.. 활동지역이 이상해요 🤔');
      return;
    }else if(_useEnterCode && (_enterCodeController.text.trim().length < 4 || _enterCodeController.text.trim().length > 10)){
      _warningHandler('흠.. 참가코드가 이상해요 🤔');
      return;
    }


    await DialogManager.showBasicDialog(
      title: '새로운 클럽을 만들까요?',
      content: '생성 후에는 클럽 정보를 수정할 수 있어요.\n지금 바로 시작해볼까요?',
      confirmText: "만들기",
      onConfirm: () async{
        int? roomId;
        AppRoute.pushLoading();
        try{
          final response = await serverManager.post('room/create', data: toMap());

          if(response.statusCode == 200){
            roomId = response.data['roomId'];
            return;
          }else if(response.statusCode == 202){
            DialogManager.showBasicDialog(title: '동일한 클럽명이 이미 존재해요', content: '같은 지역에서는 같은 이름의 채팅방을 만들 수 없어요.', confirmText: '확인');
            return;
          }
        }finally{
          AppRoute.popLoading();
          if(roomId != null){
            AppRoute.context?.pushReplacement('/room/$roomId');
          }
        }
      },
      cancelText: "취소"
    );
  }

  void _warningHandler(String title){
    DialogManager.showBasicDialog(title: title, content: '확인하고 다시 입력해 주세요!', confirmText: '확인');
  }

  toMap(){
    return {
      'roomName' : _roomNameController.text,
      'local' : _local,
      'city' : _city,
      'description' : _descriptionController.text,
      'tag' : TagFormManager.listToString(_tags),
      'useNickname' : _useNickname,
      'enterCode' : _useEnterCode ? _enterCodeController.text.trim() : ''
    };
  }
}
