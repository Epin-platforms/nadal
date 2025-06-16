import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../project/Import_Manager.dart';

class AppleManager {
  Future<void> appleLogin() async {
    AppRoute.pushLoading();

    try {
      // Apple ID 지원 여부 확인
      final bool isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple 로그인을 사용할 수 없습니다');
      }

      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 토큰 유효성 검증
      if (appleCredential.identityToken == null) {
        throw Exception('Apple 인증 토큰을 가져올 수 없습니다');
      }

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase 로그인
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 🔧 사용자 정보 업데이트 (이메일 포함)
      await _updateAppleUserInfo(userCredential, appleCredential);

      AppRoute.popLoading();
    } on SignInWithAppleAuthorizationException catch (e) {
      AppRoute.popLoading();
      if (e.code == AuthorizationErrorCode.canceled) {
        // 사용자가 취소한 경우는 에러 메시지를 표시하지 않음
        return;
      }
      DialogManager.errorHandler('Apple 로그인 인증에 실패했습니다');
      print('Apple 인증 오류: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      AppRoute.popLoading();
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    } on Exception catch (e) {
      AppRoute.popLoading();
      DialogManager.errorHandler('Apple 로그인에 실패했습니다');
      print('Apple 로그인 오류: $e');
    } catch (e) {
      AppRoute.popLoading();
      DialogManager.errorHandler('예상치 못한 오류가 발생했습니다');
      print('Apple 로그인 예외: $e');
    }
  }

  Future<void> _updateAppleUserInfo(UserCredential userCredential, AuthorizationCredentialAppleID appleCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      print('🍎 Apple 로그인 정보:');
      print('🍎 Apple Email: ${appleCredential.email}');
      print('🍎 Firebase Email: ${user.email}');

      // 🔧 이메일 우선 업데이트 (애플 계정 이메일 보장)
      if (appleCredential.email != null &&
          appleCredential.email!.isNotEmpty &&
          user.email != appleCredential.email) {
        try {
          // 신규 사용자의 경우 updateEmail 사용
          if (user.metadata.creationTime != null &&
              user.metadata.lastSignInTime != null &&
              user.metadata.creationTime!.millisecondsSinceEpoch ==
                  user.metadata.lastSignInTime!.millisecondsSinceEpoch) {
            // 첫 로그인인 경우
            await user.updateEmail(appleCredential.email!);
            print('✅ 애플 이메일 업데이트 성공: ${appleCredential.email}');
          }
        } catch (emailError) {
          print('이메일 업데이트 실패 (무시): $emailError');
          // 이메일 업데이트 실패해도 로그인은 계속 진행
        }
      }

      // 이름 조합 및 업데이트
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final String displayName = '${appleCredential.givenName ?? ''}${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty && user.displayName != displayName) {
          await user.updateDisplayName(displayName);
          print('✅ 애플 displayName 업데이트 성공: $displayName');
        }
      }

      // 사용자 정보 새로고침
      await user.reload();

    } catch (e) {
      print('Apple 사용자 정보 업데이트 실패: $e');
      // 로그인은 성공했으므로 에러 다이얼로그는 표시하지 않음
    }
  }
}