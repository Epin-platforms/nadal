import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import '../../project/Import_Manager.dart';

class KakaoManager{
  Future<void> kakaoLogin() async{
    AppRoute.pushLoading();
    final kakaoAccessToken = await getKakaoToken();

    if(kakaoAccessToken == null){
      throw Exception('올바르지 않은 계정입니다');
    }

    try{
      var provider = OAuthProvider("oidc.kakao");

      final OAuthCredential credential = provider.credential(
        idToken: kakaoAccessToken.idToken,
        accessToken: kakaoAccessToken.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final kakao.User kakaoUser = await kakaoUserInfo();

      // ✅ 최초 로그인 시 이메일과 이름 저장
      if (kakaoUser.kakaoAccount!.email != null && kakaoUser.kakaoAccount!.name != null) {
        await userCredential.user!.updateDisplayName(kakaoUser.kakaoAccount!.name);
        await userCredential.user!.verifyBeforeUpdateEmail(kakaoUser.kakaoAccount!.email!);
      }else{
        print('카카오 이메일 저장 실패');
      }
    }on FirebaseAuthException catch(e){
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    }on kakao.KakaoApiException catch(e){
      print(e);
    }catch(e){
      print('카카오 로그인 $e');
    }finally{
      AppRoute.popLoading();
    }
  }

  Future<kakao.User> kakaoUserInfo() async{
    return await kakao.UserApi.instance.me();
  }

  Future<kakao.OAuthToken?> getKakaoToken() async {
    try {
      // 카카오톡 설치 여부 확인 후 로그인 시도
      final bool isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        kakao.OAuthToken authToken = await kakao.UserApi.instance.loginWithKakaoTalk();
        return authToken;
      }

      // 카카오 계정 로그인 시도
      kakao.OAuthToken authToken = await kakao.UserApi.instance.loginWithKakaoAccount();
      await kakao.TokenManagerProvider.instance.manager.setToken(authToken);
      return authToken;
    } catch (e) {
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
      return null;
    }
  }


  Future<void> unlink() async {
    try {
      final token = await kakao.TokenManagerProvider.instance.manager.getToken();

      if (token != null) {
        await kakao.UserApi.instance.unlink();
      }
    } on kakao.KakaoAuthException catch(e){
      DialogManager.errorHandler('카카오계정 연결해제에 실패하였습니다');
      print("카카오 로그아웃 실패: $e");
    }
  }


}