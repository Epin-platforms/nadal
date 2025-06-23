
import 'package:dio/dio.dart';
import 'package:my_sports_calendar/manager/form/room/Tag_Form_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

import '../../manager/project/Import_Manager.dart';

class EditRoomProvider extends ChangeNotifier{
  EditRoomProvider(Map room){
    _originRoom = room;
    _tags = TagFormManager.stringToList(_originRoom['tag']);
    _local = _originRoom['local'];
    _city = _originRoom['city'];

    _useEnterCode = _originRoom['enterCode'].isNotEmpty;

    _roomNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagController = TextEditingController(text: '#');
    _enterCodeController = TextEditingController();
  }

  late Map _originRoom;
  Map get originRoom => _originRoom;

  //프로필 이미지
  final _picker = ImagePicker();
  File? _selectedImage;

  Future<void> get pickImage => _pickImage();
  File? get selectedImage => _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  //닉네임
  late final TextEditingController _roomNameController;
  TextEditingController get roomNameController => _roomNameController;

  //지역
  String _local = '';
  String _city = '';

  String get local => _local;
  String get city => _city;

  void setCity(String value){
    if(city != value){
      _city = value;
      notifyListeners();
    }
  }

  void setLocal(String value){
    if(local != value){
      if(city.isNotEmpty){
        _city = '';
      }
      _local = value;
      notifyListeners();
    }
  }

  //패스워드사용여부
  bool _useEnterCode = true;
  bool get useEnterCode => _useEnterCode;

  //익명 사용여부 제거

  //방 설명
  late final TextEditingController _descriptionController;
  TextEditingController get descriptionController => _descriptionController;


  //태그
  List<String> _tags = [];
  List<String> get tags => _tags;
  late final TextEditingController _tagController;
  TextEditingController get tagController => _tagController;

  void setTag(String value){
    final val = value.trim();
    if(val.endsWith(',')){
      var tag = val.replaceRange(value.length - 1, null, '').replaceAll('#', '');

      if(tag.isEmpty){
        DialogManager.showBasicDialog(title: '앗! 태그가 이상해요', content: '\',(쉼표)\'로 태그를 구분해주세요', confirmText: '확인');
        _tagController.text = '#';
        notifyListeners();
        return;
      }

      final formTag = TextFormManager.removeSpace(tag);
      _tags.add('#$formTag');
      _tagController.text = '#';
      notifyListeners();
    }
  }


  void removeTag(int index){
    _tags.removeAt(index);
    notifyListeners();
  }

  //방 참가코드
  late final TextEditingController _enterCodeController;
  TextEditingController get enterCodeController => _enterCodeController;

  Future<void> updateRoom() async{
    if(TextFormManager.removeSpace(_roomNameController.text).isEmpty || _roomNameController.text.length > 30){
      DialogManager.warningHandler('흠.. 클럽명이 이상해요 🤔');
      return;
    }else if(_city.isEmpty){
      DialogManager.warningHandler('흠.. 활동지역이 이상해요 🤔');
      return;
    }else if(_useEnterCode && (_enterCodeController.text.trim().length < 4 || _enterCodeController.text.trim().length > 10)){
      DialogManager.warningHandler('흠.. 참가코드가 이상해요 🤔');
      return;
    }

    final updateField = await setUpdateField();

      if(updateField.keys.isEmpty){
        DialogManager.warningHandler('흠.. 변경할 내용이 없는데요? 🤔');
        return;
      }

     await _startUpdate(updateField);
  }


  Future<Map<String, dynamic>> setUpdateField() async{
    Map<String, dynamic> field = {};

    try{
      if(_selectedImage != null){
        field.addAll({
          'roomImage': MultipartFile.fromFileSync(_selectedImage!.path, filename: _selectedImage!.path.split('/').last),
        });
      }

      if(_originRoom['roomName'] != _roomNameController.text){
        field.addAll(
            {
              'roomName' : _roomNameController.text,
              'local' : _local
            }
        );
      }

      if(_originRoom['description'] != _descriptionController.text){
        field.addAll(
            {'description' : _descriptionController.text}
        );
      }

      if(_originRoom['tag'] != TagFormManager.listToString(tags)){
        field.addAll(
            {'tag' : TagFormManager.listToString(tags)}
        );
      }

      if(_useEnterCode && (_originRoom['enterCode'].isEmpty) ||
          (_enterCodeController.text.trim() != _originRoom['enterCode'])){ //원레 비번이 비어있는 상태에서 엔터 코드사용으로 했거나 엔터코드랑 기존엔터코드가 다른데 사용하기를 했거나
        field.addAll(
            {
              'enterCode' : _enterCodeController.text.trim()
            }
        );
      }

      if(!_useEnterCode && _originRoom['enterCode'].isNotEmpty){ //만약 기존 엔터코드가있는데 엔터코드 사용안함 설정
        field.addAll(
            {
              'enterCode' : ''
            }
        );
      }


      if(_local != _originRoom['local']){
        field.addAll(
            {
              'local' : _local
            }
        );
      }

      if(_city != _originRoom['city']){
        field.addAll(
            {
              'city' : _city
            }
        );
      }

      if(field.isNotEmpty){
        field.addAll(
            {'roomId' : originRoom['roomId']}
        );
      }

    }catch(e, stack){
      print(e);
      return {

      };
    }

    return field;
  }


  Future<void> _startUpdate(Map<String, dynamic> updateField) async{
    if(updateField.isEmpty) return;
    AppRoute.pushLoading();
    int? state;
    try{
      final isMultipart = updateField.values.any((value) => value is MultipartFile);
      final dataToSend = isMultipart ? FormData.fromMap(updateField) : updateField;

      print(dataToSend);

      final res = await serverManager.put('room/update', data: dataToSend);

      state = res.statusCode;
      if(res.statusCode == 200){
        await AppRoute.context?.read<RoomsProvider>().updateRoom(_originRoom['roomId']);
      }
    }catch(e, stack){
      print(e);
      print(stack);
      state = 404;
    }finally{
      AppRoute.popLoading();
      if(state == 202) {
        DialogManager.showBasicDialog(title: '동일한 클럽명이 이미 존재해요', content: '같은 지역에서는 같은 이름의 채팅방을 만들 수 없어요.', confirmText: '확인');
      }else if(state == 200){
        await DialogManager.showBasicDialog(title: '업데이트 성공', content: '해당 내용을 성공적으로 저장했어요', confirmText: '확인');
        AppRoute.context?.pop('update');
      }else{
        DialogManager.showBasicDialog(title: '업데이트 실패', content: '클럽 업데이트에 실패했어요\n나중에 다시 시도해주세요', confirmText: '확인');
      }
    }
  }
}