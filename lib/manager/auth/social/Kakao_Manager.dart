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

  // 카카오 공유 - 딥링크 파라미터 처리 개선
  Future<void> sendKakaoInviteForm(ShareParameter item) async {
    try {
      // 기본값 설정 및 안전한 파라미터 처리
      final imageUrl = item.imageUrl ?? dotenv.get('APP_SCHEDULE_IMAGE');
      final baseLink = item.link ?? 'https://epin.co.kr/38';

      // 라우팅 파라미터가 있는 경우 딥링크 생성
      final String linkString;
      if (item.routing.isNotEmpty) {
        // 딥링크 형태로 변환 (URL 인코딩 적용)
        final encodedRouting = Uri.encodeComponent(item.routing);
        linkString = '$baseLink?routing=$encodedRouting';
        print('생성된 딥링크: $linkString');
      } else {
        linkString = baseLink;
      }

      // URI 파싱 안전성 강화
      final Uri link;
      final Uri imageUri;

      try {
        link = Uri.parse(linkString);
        imageUri = Uri.parse(imageUrl);
        print('파싱된 링크: $link');
        print('파싱된 이미지: $imageUri');
      } catch (e) {
        print('URI 파싱 실패: $e');
        return;
      }

      // 카카오 공유 템플릿 생성
      final template = FeedTemplate(
        content: Content(
          title: item.title,
          description: item.subTitle,
          imageUrl: imageUri,
          link: Link(
            webUrl: link,
            mobileWebUrl: link,
            // 앱 실행 파라미터 개선
            androidExecutionParams: _createExecutionParams(item.routing),
            iosExecutionParams: _createExecutionParams(item.routing),
          ),
        ),
        buttons: [
          Button(
            title: '보러가기',
            link: Link(
              webUrl: link,
              mobileWebUrl: link,
              androidExecutionParams: _createExecutionParams(item.routing),
              iosExecutionParams: _createExecutionParams(item.routing),
            ),
          ),
        ],
      );

      print('카카오 공유 템플릿 생성 완료');
      print('라우팅 파라미터: ${item.routing}');

      // 카카오톡 공유 실행
      bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

      if (isKakaoTalkSharingAvailable) {
        try {
          print('카카오톡 앱 공유 시도');
          Uri uri = await ShareClient.instance.shareDefault(template: template);
          await ShareClient.instance.launchKakaoTalk(uri);
          print('카카오톡 앱 공유 성공');
        } catch (error) {
          print('카카오톡 앱 공유 실패: $error');
        }
      } else {
        try {
          print('웹 공유 시도');
          Uri shareUrl = await WebSharerClient.instance.makeDefaultUrl(template: template);
          await launchBrowserTab(shareUrl, popupOpen: true);
          print('웹 공유 성공');
        } catch (error) {
          print('웹 공유 실패: $error');
        }
      }
    } on kakao.KakaoApiException catch (e) {
      print('카카오 API 공유 오류: $e');
      DialogManager.errorHandler('공유하기에 실패하였습니다');
    } catch (e) {
      print('카카오 초대 실패: $e');
      DialogManager.errorHandler('공유하기에 실패하였습니다');
    }
  }

  // 실행 파라미터 생성 헬퍼 함수
  Map<String, String> _createExecutionParams(String routing) {
    if (routing.isEmpty) {
      return {};
    }

    return {
      'routing': routing,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}