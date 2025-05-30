import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../../../model/share/Share_Parameter.dart';
import '../../project/Import_Manager.dart';

class KakaoManager {
  Future<void> kakaoLogin() async {
    AppRoute.pushLoading();

    try {
      final kakaoAccessToken = await getKakaoToken();

      if (kakaoAccessToken == null) {
        throw Exception('올바르지 않은 계정입니다');
      }

      var provider = OAuthProvider("oidc.kakao");

      final OAuthCredential credential = provider.credential(
        idToken: kakaoAccessToken.idToken,
        accessToken: kakaoAccessToken.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final kakao.User kakaoUser = await kakaoUserInfo();

      // ✅ 최초 로그인 시 이메일과 이름 저장 (안전하게 개선)
      if (kakaoUser.kakaoAccount?.email != null && kakaoUser.kakaoAccount?.name != null) {
        try {
          await userCredential.user!.updateDisplayName(kakaoUser.kakaoAccount!.name);
          // verifyBeforeUpdateEmail 제거 - 신규 가입자에게는 적용되지 않음
        } catch (e) {
          print('카카오 사용자 정보 업데이트 실패: $e');
        }
      } else {
        print('카카오 이메일 저장 실패');
      }

    } on FirebaseAuthException catch (e) {
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    } on kakao.KakaoApiException catch (e) {
      print(e);
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
    } catch (e) {
      print('카카오 로그인 $e');
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<kakao.User> kakaoUserInfo() async {
    return await kakao.UserApi.instance.me();
  }

  Future<kakao.OAuthToken?> getKakaoToken() async {
    try {
      // 카카오톡 설치 여부 확인 후 로그인 시도
      final bool isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        kakao.OAuthToken authToken;
        try {
          authToken = await kakao.UserApi.instance.loginWithKakaoTalk();
          await kakao.TokenManagerProvider.instance.manager.setToken(authToken);
        } catch (error) {
          // 카카오톡 로그인 실패 시 카카오 계정 로그인으로 fallback
          authToken = await kakao.UserApi.instance.loginWithKakaoAccount();
          await kakao.TokenManagerProvider.instance.manager.setToken(authToken);
        }
        return authToken;
      }

      // 카카오 계정 로그인 시도
      kakao.OAuthToken authToken = await kakao.UserApi.instance.loginWithKakaoAccount();
      await kakao.TokenManagerProvider.instance.manager.setToken(authToken);
      AppRoute.popLoading();
      return authToken;
    } on kakao.KakaoAuthException catch (e) {
      print('카카오 인증 오류: $e');
      AppRoute.popLoading();
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
      return null;
    } on kakao.KakaoClientException catch (e) {
      print('카카오 클라이언트 오류: $e');
      AppRoute.popLoading();
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
      return null;
    } catch (e) {
      print('카카오 토큰 획득 실패: $e');
      AppRoute.popLoading();
      DialogManager.errorHandler('카카오 로그인에 실패하였습니다');
      return null;
    }
  }

  Future<void> unlink() async {
    try {
      final token = await kakao.TokenManagerProvider.instance.manager.getToken();

      if (token != null) {
        await kakao.UserApi.instance.unlink();
        // 토큰 매니저에서도 정리
        await kakao.TokenManagerProvider.instance.manager.clear();
      }
    } on kakao.KakaoAuthException catch (e) {
      DialogManager.errorHandler('카카오계정 연결해제에 실패하였습니다');
      print("카카오 로그아웃 실패: $e");
    } catch (e) {
      print("카카오 연결해제 예외: $e");
    }
  }

  // 카카오 공유
  Future<void> sendKakaoInviteForm(ShareParameter item) async {
    try {
      final imageUrl = item.imageUrl ?? dotenv.get('APP_SCHEDULE_IMAGE');
      final linkString = item.link ?? 'https://epin.co.kr/38';

      // URI 파싱 안전성 강화
      final Uri link;
      final Uri imageUri;

      try {
        link = Uri.parse(linkString);
        imageUri = Uri.parse(imageUrl);
      } catch (e) {
        print('URI 파싱 실패: $e');
        return;
      }


      final template = FeedTemplate(
        content: Content(
          title: item.title,
          description: item.subTitle,
          imageUrl: imageUri,
          link: Link(
              webUrl: link,
              mobileWebUrl: link,
              androidExecutionParams: {
                'routing': item.routing
              },
              iosExecutionParams: {
                'routing': item.routing
              }
          ),
        ),
        buttons: [
          Button(
            title: '보러가기',
            link: Link(
                webUrl: link,
                mobileWebUrl: link,
                androidExecutionParams: {
                  'routing': item.routing
                },
                iosExecutionParams: {
                  'routing': item.routing
                }
            ),
          ),
        ],
      );

      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

      if (isKakaoTalkSharingAvailable) {
        try {
          Uri uri = await ShareClient.instance.shareDefault(template: template);
          await ShareClient.instance.launchKakaoTalk(uri);
        } catch (error) {
          print('카카오톡 공유 실패 $error');
        }
      } else {
        try {
          Uri shareUrl = await WebSharerClient.instance.makeDefaultUrl(template: template);
          await launchBrowserTab(shareUrl, popupOpen: true);
        } catch (error) {
          print('카카오톡 공유 실패 $error');
        }
      }
    } on kakao.KakaoApiException catch (e) {
      print('카카오 API 공유 오류: $e');
    } catch (e) {
      print('카카오 초대 실패: $e');
    }
  }
}
