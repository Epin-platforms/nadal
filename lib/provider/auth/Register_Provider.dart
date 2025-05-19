import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:my_sports_calendar/manager/auth/social/Kakao_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';


class RegisterProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _nickController = TextEditingController();
  final _birthYearController = TextEditingController();
  final List<String> genderList = ['M', 'F'];

  int _careerDate = 0;
  String _selectedGender = '';
  String _selectedLocal = '';
  String _selectedCity = '';
  String? _phone;

  // ✅ 컨트롤러 getter
  TextEditingController get emailController => _emailController;
  TextEditingController get nameController => _nameController;
  TextEditingController get nickController => _nickController;
  TextEditingController get birthYearController => _birthYearController;

  // ✅ 값 getter
  int get careerDate => _careerDate;
  String get selectedGender => _selectedGender;
  String get selectedLocal => _selectedLocal;
  String get selectedCity => _selectedCity;

  // ✅ 값 setter
  void setGender(String value) {
    _selectedGender = value;
    notifyListeners();
  }

  void setLocal(String value) {
    if(_selectedLocal != value){
      if(_selectedCity.isNotEmpty){
        _selectedCity = '';
      }
      _selectedLocal = value;
    }
    notifyListeners();
  }

  void setCity(String value) {
    _selectedCity = value;
    notifyListeners();
  }

  void setCareerDate(int year) {
    _careerDate = year;
    notifyListeners();
  }


  // ✅ 폼 초기화
  bool _loading = false;
  bool get loading => _loading;

  //이메일 인증 패스
  bool _isEmailCertification = true;
  bool get isEmailCertification => _isEmailCertification;

  int? _verificationCode = null;
  int? get verificationCode => _verificationCode;


  bool _visibleNameSpace = true;
  bool _emailSpace = true;
  bool _genderSpace = true;
  bool _birthYearSpace = true;

  bool get visibleNameSpace => _visibleNameSpace;
  bool get emailSpace => _emailSpace;
  bool get genderSpace => _genderSpace;
  bool get  birthYearSpace => _birthYearSpace;


  void resetForm() async{
    print('호출');
    _loading = true;
    notifyListeners();

    try{
      final userData = await getUserData();

      if(userData['email'].isEmpty){
        _isEmailCertification = false;
        _emailSpace = true;
      }
      _verificationCode = userData['verificationCode'];
      _emailController.text = userData['email'];
      _nameController.text = userData['name'];
      if(_verificationCode != null && _nameController.text.isNotEmpty){
        _visibleNameSpace = false;
      }
      _nickController.text = userData['nickName'];
      _phone = userData['phone'];
      _birthYearController.text = '${userData['birthYear'] == 0 ? '' : userData['birthYear']}';
      if(_verificationCode != null && _birthYearController.text.isNotEmpty){
        _birthYearSpace = false;
      }
      _selectedGender = userData['gender'];
      if(_verificationCode != null && _selectedGender.isNotEmpty){
        _genderSpace = false;
      }
      _selectedLocal = '';
      _selectedCity = '';
      _careerDate = 0;

      _loading = false;
      notifyListeners();
    }catch(error){
      DialogManager.errorHandler('예상치 못한 이유로 회원 정보를 불러오지 못했습니다.');
    }
  }

  Future getUserData() async{
    if(_auth.currentUser != null){
      final map = {
        'email' : _auth.currentUser!.email ?? '',
        'name' : _auth.currentUser!.displayName ?? '',
        'nickName' : _auth.currentUser!.displayName ?? '',
        'birthYear' : 0,
        'phone' : null,
        'gender' : '',
        'profileImage' : null,
        'verificationCode' : null
      };

      final social = _auth.currentUser!.providerData[0].providerId;

      if(social == "oidc.kakao"){ //카카오로 불러올 경우
        final kakaoUser = await KakaoManager().kakaoUserInfo();
        final account = kakaoUser.kakaoAccount;

        if(account != null){
          if(_auth.currentUser!.email == null){
            map['email'] = account.email ?? '';
          }
          map['name'] = account.name ?? '';
          map['birthYear'] = int.tryParse(account.birthyear ?? '') ?? 0;
          map['phone'] = AuthFormManager.phoneForm(account.phoneNumber);
          map['gender'] = account.gender == null ? '' : (account.gender == Gender.male ? 'M' : (account.gender == Gender.female ? 'F' : ''));
          map['verificationCode'] = kakaoUser.id;
        }
      }
      return map;
    }
  }


  //다른 플랫폼 로그인 후 다시 카카오로 불러오기
  void connectKakao() async{
     final token = await KakaoManager().getKakaoToken();
     if(token == null){
        return;
     }
     resetForm();
  }


  // ✅ 사용자 데이터 추출
  Map<String, dynamic> toMap() {
    return {
      'email' : _emailController.text.trim(),
      'name': _nameController.text.trim(),
      'nickName': _nickController.text.trim(),
      'birthYear': int.tryParse(_birthYearController.text.trim()),
      'gender': _selectedGender,
      'local': _selectedLocal,
      'city': _selectedCity,
      'phone' : _phone,
      'career': AuthFormManager.careerYearToDate(_careerDate, null),
      'level' : AuthFormManager.careerToLevel(_careerDate),
      'verificationCode' : _verificationCode,
      'social' : _auth.currentUser!.providerData[0].providerId
    };
  }

  //가입하기
  void signUp() async{
    if(_nameController.text.isEmpty || _nameController.text.length > 10){
      DialogManager.warningHandler('흠.. 이름이 이상해요 🤔');
      return;
    }else if(_birthYearController.text.isEmpty || _birthYearController.text.length != 4){
      DialogManager.warningHandler('흠.. 출생연도가 이상해요 🤔');
      return;
    }else if(_selectedGender.isEmpty){
      DialogManager.warningHandler('성별이 선택되지 않았어요 🤔');
      return;
    }
    //공통
    if(_nickController.text.isEmpty || _nickController.text.length > 10){
      DialogManager.warningHandler('흠.. 닉네임이 이상해요 🤔');
      return;
    }else if(_selectedLocal.isEmpty){
      DialogManager.warningHandler('흠.. 지역이 선택되지 않았어요 🤔');
      return;
    }else if(_selectedCity.isEmpty){
      DialogManager.warningHandler('흠.. 시/구/군이 선택되지 않았어요 🤔');
      return;
    }

    //만들기
    final user = toMap();
    _loading = true;
    final res = await serverManager.post('user/signUp', data: user);

    if(res.statusCode == 200){
      final provider = AppRoute.context?.read<UserProvider>();

      if(provider != null){
        await provider.fetchUserData(loading: false);
        AppRoute.context?.go('/my');
      }else{
        DialogManager.errorHandler('예상치 못한 오류가 발생하였습니다\n앱을 완전히 종료 후 다시 접속해주세요');
      }
    }else if(res.statusCode == 204){ //같은 아이디나 이메일이 존재함
      final data = res.data;
      final emailData = (data['email'] as String).split('@');
      final namePart = emailData.first;
      final masked = namePart.length <= 2
          ? '${namePart[0]}*'
          : namePart.replaceRange(2, namePart.length, '*' * (namePart.length - 2));

      final email = '$masked@${emailData.last}';
      final social = (data['social'] as String).contains('kakao') ? "카카오" : (data['social'] as String).contains('google') ? "구글" : "애플";
      await DialogManager.showBasicDialog(title: "같은 계정이 존재해요", content: "$social로\n$email계정이 존재해요", confirmText: '로그인 페이지로', onConfirm: (){
        final provider = AppRoute.context?.read<UserProvider>();
        if(provider != null){
          provider.logout(true);
        }});
    }

    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _nickController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }
}