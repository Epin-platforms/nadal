import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:my_sports_calendar/manager/auth/social/Kakao_Manager.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/form/auth/Auth_Form_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class KakaoProvider extends ChangeNotifier{
  final _auth = FirebaseAuth.instance;

  KakaoProvider(Map user){
    _originUser = user;
  }

  //기존 정보
  Map? _originUser;

  //새로 불러올 정보
  String? _name;
  int? _birthYear;
  String? _gender;
  String? _email; //카카오로 불러온 사용자만 다시 불러오기
  String? _phone;

  Map? get originUser => _originUser;

  String? get name => _name;
  int? get birthYear => _birthYear;
  String? get gender => _gender;
  String? get email => _email;
  String? get phone => _phone;


  int? _kakaoId;
  int? get kakaoId => _kakaoId;

  late final String socialType;

  toMap(){
    Map map = {
      'verificationCode' : _kakaoId,
      'phone' : _phone,
      'name' : _name,
      'birthYear' : _birthYear,
      'gender' : _gender,
    };

    final bool emailContain = _originUser?['social'] == "oidc.kakao";

    if(emailContain){
      map.addAll({'email' : _email});
    }

    return map;
  }


  Future<void> getKakao() async {
    AppRoute.pushLoading();

    try {
      final res = await KakaoManager().getKakaoToken();
      if (res == null) {
        AppRoute.popLoading();
        return _showError('카카오 토큰을 가져오지 못했어요.');
      }

      final user = await KakaoManager().kakaoUserInfo();

      _kakaoId = user.id;
      _name = user.kakaoAccount?.name;
      _birthYear = user.kakaoAccount?.birthyear != null
          ? int.tryParse(user.kakaoAccount!.birthyear!)
          : null;
      _gender = _parseGender(user.kakaoAccount?.gender);
      _phone = AuthFormManager.phoneForm(user.kakaoAccount?.phoneNumber);

      if (_originUser?['social'] == "oidc.kakao") {
        _email = user.kakaoAccount?.email;
      }

      notifyListeners();

      // ✅ null 체크
      if (_name == null || _birthYear == null || _gender == null) {
        AppRoute.popLoading();
        return _showError('필요한 정보를 가져오지 못했어요\n카카오에서 본인인증을 완료해 주세요!');
      }

      // ✅ 변경된 내용이 없는 경우
      final noChange = _originUser?['name'] == _name &&
          _originUser?['birthYear'] == _birthYear &&
          _originUser?['gender'] == _gender &&
          _originUser?['phone'] == _phone;

      if (noChange) {
        return _showInfo('변경된 내용이 없네요', '저장할 변경사항이 없어요.');
      }

      AppRoute.popLoading();
      // ✅ 업데이트 실행
      updateKakaoInfo();

    } catch (e, stack) {
      AppRoute.popLoading();
      _showError('오류가 발생했어요. 다시 시도해 주세요.');
      debugPrintStack(label: 'getKakao 에러', stackTrace: stack);
    }
  }

// 성별 파싱을 함수로 분리
  String _parseGender(Gender? gender) {
    switch (gender) {
      case Gender.male:
        return 'M';
      case Gender.female:
        return 'F';
      default:
        return 'M';
    }
  }

// 메시지 보여주기 헬퍼
  void _showInfo(String title, String content) {
    DialogManager.showBasicDialog(title: title, content: content, confirmText: '확인');
  }

// 오류 메시지 헬퍼
  void _showError(String message) {
    DialogManager.errorHandler(message);
  }


  Future<void> resetKakao() async{
    await KakaoManager().unlink();
    await getKakao();
  }

  Future<void> updateKakaoInfo() async{
    final context = AppRoute.context;

    await DialogManager.showBasicDialog(
        title: '업데이트를 진행할까요?',
        content: '불러온 내용으로 회원님의정보를 업데이트 할게요',
        confirmText: '업데이트',
        onConfirm: () async{
          bool state = false;
          AppRoute.pushLoading();
          try{
            final response = await serverManager.put('user/verification', data: toMap());

            if(response.statusCode == 200){
              await context?.read<UserProvider>().updateProfile();
              state = true;
            }
          }catch(error){
            print(error);
          }finally{
            AppRoute.popLoading();
            if(state){
              DialogManager.showBasicDialog(title: '업데이트 완료', content: '회원 정보를 성공적으로 업데이트 했어요', confirmText: "확인");
            }
          }
        },
        cancelText: '취소'
    );

  }
}