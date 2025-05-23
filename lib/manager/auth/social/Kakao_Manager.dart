import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../../../model/share/Share_Parameter.dart';
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



  //카카오 공유
  Future<void> sendKakaoInviteForm(ShareParameter item) async {
    try {
      final imageUrl = item.imageUrl ?? dotenv.get('APP_SCHEDULE_IMAGE');
      final link = Uri.parse(item.link ?? 'https://epin.co.kr/38');
      final params = {
        'routing' : item.routing
      };
      final template = FeedTemplate(
        content: Content(
          title: item.title,
          description: item.subTitle,
          imageUrl: Uri.parse(imageUrl),
          link: Link(
              webUrl: link,
              mobileWebUrl: link,
              androidExecutionParams: params,
              iosExecutionParams: params
          ),
        ),
        buttons: [
          Button(
            title: '보러가기',
            link: Link(
                webUrl: link,
                mobileWebUrl: link,
                androidExecutionParams: params,
                iosExecutionParams: params
            ),
          ),
        ],
      );

      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

      if(isKakaoTalkSharingAvailable){
        try{
          Uri uri =
          await ShareClient.instance.shareDefault(template: template);
          await ShareClient.instance.launchKakaoTalk(uri);
        }catch(error){
          print('카카오톡 공유 실패 $error');
        }
      }else{
        try{
          Uri shareUrl = await WebSharerClient.instance
              .makeDefaultUrl(template: template);
          await launchBrowserTab(shareUrl, popupOpen: true);
        }catch(error){
          print('카카오톡 공유 실패 $error');
        }
      }
    } catch (e) {
      print('카카오 초대 실패: $e');
    }
  }
}