import 'package:google_sign_in/google_sign_in.dart';
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
  bool _isEmailCertification = false;
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

  Future<void> resetForm() async{
    print('resetForm 호출');
    _setLoading(true);

    try{
      final userData = await getUserData();

      if((userData['email'] as String).isNotEmpty){
        _isEmailCertification = true;
        _emailSpace = false;
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

      print('resetForm 완료 - 데이터 적용됨');
      print('이름: ${_nameController.text}');
      print('출생연도: ${_birthYearController.text}');
      print('성별: $_selectedGender');
      print('인증코드: $_verificationCode');

    }catch(error){
      print('resetForm 에러: $error');
      DialogManager.errorHandler('예상치 못한 이유로 회원 정보를 불러오지 못했습니다.');
    } finally {
      _setLoading(false);
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
      print('🔍 Social Provider: $social');
      print('🔍 Firebase Email: ${_auth.currentUser!.email}');

      if(social == "oidc.kakao"){
        // 카카오 로그인 처리
        try {
          final kakaoUser = await KakaoManager().kakaoUserInfo();
          final account = kakaoUser.kakaoAccount;

          if(account != null){
            // 🔧 이메일 조건 개선: Firebase에 이메일이 없거나 비어있을 때
            if(_auth.currentUser!.email == null || _auth.currentUser!.email!.isEmpty){
              map['email'] = account.email ?? '';
            }
            map['name'] = account.name ?? '';
            map['birthYear'] = int.tryParse(account.birthyear ?? '') ?? 0;
            map['phone'] = AuthFormManager.phoneForm(account.phoneNumber);
            map['gender'] = account.gender == null ? '' : (account.gender == Gender.male ? 'M' : (account.gender == Gender.female ? 'F' : ''));
            map['verificationCode'] = kakaoUser.id;
          }
        } catch (e) {
          print('❌ 카카오 정보 가져오기 실패: $e');
        }
      } else if (social == "google.com") {
        // 🔧 구글 로그인 처리
        try {
          // Firebase Auth에서 이메일이 없을 경우 GoogleSignIn에서 직접 가져오기
          if(_auth.currentUser!.email == null || _auth.currentUser!.email!.isEmpty) {
            final googleSignIn = GoogleSignIn(
              scopes: ['email', 'profile'],
              signInOption: SignInOption.standard,
            );
            final currentUser = googleSignIn.currentUser;

            if (currentUser != null && currentUser.email.isNotEmpty) {
              map['email'] = currentUser.email;
              print('✅ 구글에서 이메일 가져옴: ${currentUser.email}');
            } else {
              print('⚠️ GoogleSignIn currentUser가 null이거나 이메일이 비어있음');
            }
          }
        } catch (e) {
          print('❌ 구글 정보 가져오기 실패: $e');
        }
      } else if (social == "apple.com") {
        // 🔧 애플 로그인 처리 추가
        try {
          // 애플의 경우 첫 로그인 시에만 이메일/이름 제공
          // Firebase Auth에 저장된 정보가 우선이므로 별도 처리 불필요
          // 하지만 디버그 로그는 추가
          print('🍎 애플 로그인 - Firebase에서 정보 사용');
          print('🍎 Firebase Email: ${_auth.currentUser!.email}');
          print('🍎 Firebase DisplayName: ${_auth.currentUser!.displayName}');

          // 만약 Firebase에 이메일이 없다면 사용자에게 직접 입력 요청
          if(_auth.currentUser!.email == null || _auth.currentUser!.email!.isEmpty) {
            print('⚠️ 애플 로그인: 이메일 정보 없음 - 사용자 입력 필요');
            map['email'] = ''; // 빈 문자열로 설정하여 이메일 입력 필드 표시
          }
        } catch (e) {
          print('❌ 애플 정보 처리 실패: $e');
        }
      }

      // 🔍 디버그 로그 추가
      print('🔍 최종 이메일: ${map['email']}');

      return map;
    }
  }

  // ✅ 카카오 연결 개선 - 비동기 처리 및 에러 핸들링 강화
  void connectKakao() async{
    print('connectKakao 시작');
    _setLoading(true);

    try {
      final token = await KakaoManager().getKakaoToken();
      if(token == null){
        print('카카오 토큰 획득 실패');
        DialogManager.errorHandler('카카오 로그인에 실패했습니다.');
        return;
      }

      print('카카오 토큰 획득 성공, resetForm 호출');
      await Future.delayed(Duration(milliseconds: 100)); // 토큰 설정 대기
      await resetForm(); // await 추가

    } catch (error) {
      print('connectKakao 에러: $error');
      DialogManager.errorHandler('카카오 정보를 불러오는데 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ 로딩 상태 관리 헬퍼
  void _setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
  }

  // ✅ 사용자 데이터 추출
  Map<String, dynamic> toMap() {
    return {
      'email' : _emailController.text.trim().isEmpty ? _auth.currentUser?.email ?? '' : _emailController.text.trim(),
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
    _setLoading(true);

    try {
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
        print(data);
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
            provider.logout(true, false);
          }});
      }
    } catch (error) {
      print('회원가입 에러: $error');
      DialogManager.errorHandler('회원가입 중 오류가 발생했습니다.');
    } finally {
      _setLoading(false);
    }
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