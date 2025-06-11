import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class ProfileEditProvider extends ChangeNotifier{

  ProfileEditProvider(Map user){
    setProfileEditInit(user);
  }

  late Map _originUser;

  Map get originUser => _originUser;

  setProfileEditInit(Map user) async {
    _originUser = user;
    _nickController = TextEditingController();
    _careerController = TextEditingController();
    _local = _originUser['local'];
    _city = _originUser['city'];

    //if(_originUser['verificationCode'] == null){
    _nameController = TextEditingController();
    _gender = _originUser['gender'];
    _birthYearController = TextEditingController();
    //}
  }

  //여기부터 편집가능

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
  late final TextEditingController _nickController;
  TextEditingController get nickController => _nickController;

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

  //구력
  late final TextEditingController _careerController;
  TextEditingController get careerController => _careerController;


  //이름
  late final TextEditingController _nameController;

  //성별
  String? _gender;

  //출생연도
  late final TextEditingController _birthYearController;

  TextEditingController get nameController => _nameController;
  TextEditingController get birthYearController => _birthYearController;
  String? get gender => _gender;


  void setGender(String value){
    if(value != _gender){
      _gender = value;
      notifyListeners();
    }
  }

  void saveProfile() async{
    //인증안된 사용자
    if(_originUser['verificationCode'] == null){
      if(_nameController.text.trim().isEmpty || _nameController.text.trim().length > 10){
        _warningHandler('흠.. 이름이 이상해요 🤔');
        return;
      }else if(_gender == null){
        _warningHandler('흠.. 성별이 이상해요 🤔');
        return;
      }else if(_birthYearController.text.trim().length != 4){
        _warningHandler('흠.. 출생연도가 이상해요 🤔');
        return;
      }
    }

    //공통
    if(_nickController.text.trim().isEmpty || _nickController.text.trim().length > 7){
      _warningHandler('흠.. 닉네임이 이상해요 🤔');
      return;
    }else if(_city.isEmpty){
      _warningHandler('흠.. 시/구/군이 이상해요 🤔');
      return;
    }else if(_careerController.text.trim().isEmpty || _careerController.text.trim().length > 2){
      _warningHandler('흠.. 구력이 이상해요 🤔');
      return;
    }

    //에러 헨들러 종료 후 업데이트 바뀌는 데이터만 보내기
    Map<String, dynamic> data = await createEditSaveForm();

    if(data.isEmpty){
      _warningHandler('변경할 내용이 없네요 🤔');
      return;
    }

    _saveStart(data);
  }

  void _saveStart(Map<String, dynamic> sendData) async {
    final context = AppRoute.context;

    AppRoute.pushLoading();
    bool complete = false;

    try {
      // ✅ MultipartFile이 있다면 FormData 변환
      final isMultipart = sendData.values.any((value) => value is MultipartFile);
      final dataToSend = isMultipart ? FormData.fromMap(sendData) : sendData;

      final response = await serverManager.put('user/update', data: dataToSend);

      if (response.statusCode == 200) {
        complete = true;
        await context?.read<UserProvider>().updateProfile();
      } else {
        throw Exception('Update failed with status ${response.statusCode}');
      }
    } catch (e, stack) {
      print('에러 발생: $e');
      print(stack);
    } finally {
      AppRoute.popLoading();
      if (complete) {
        if(context != null){
          SnackBarManager.showCleanSnackBar(context, "프로필을 성공적으로 업데이트 했습니다");
          context.pop();
        }
      }
    }
  }

  void _warningHandler(String title){
    DialogManager.showBasicDialog(title: title, content: '확인하고 다시 입력해 주세요!', confirmText: '확인');
  }

  Future<Map<String, dynamic>> createEditSaveForm() async{
    Map<String, dynamic> sendData = {};

    if(_selectedImage != null){
      sendData.addAll({
        'profileImage': await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!.path.split('/').last
        ),
      });
    }

    if(_originUser['nickName'] != _nickController.text.trim()){
      sendData.addAll({
        'nickName' : _nickController.text.trim()
      });
    }

    if(_originUser['local'] != _local){
      sendData.addAll({
        'local' : _local
      });
    }

    if(_originUser['city'] != _city){
      sendData.addAll({
        'city' : _city
      });
    }

    if(AuthFormManager.careerDateToYearText(_originUser['career'])
        .replaceAll('초보', '0')
        .replaceAll('?', '0')
        .replaceAll('년', '') != _careerController.text.trim()){
      final DateTime _date = DateTimeManager.parseUtcToLocal(_originUser['career']);
      final int year =  int.parse(_careerController.text.trim());
      sendData.addAll({
        'career': AuthFormManager.careerYearToDate(year, _date.month)
      });
    }

    if(_originUser['verificationCode'] == null){
      if(_originUser['name'] != _nameController.text.trim()){
        sendData.addAll({
          'name' : _nameController.text.trim()
        });
      }

      if(_originUser['gender'] != _gender){
        sendData.addAll({
          'gender' : _gender
        });
      }

      if(_originUser['birthYear'] != _birthYearController.text.trim()){
        final birthYear = int.parse(_birthYearController.text.trim());
        sendData.addAll({
          'birthYear' : birthYear
        });
      }
    }

    return sendData;
  }
}