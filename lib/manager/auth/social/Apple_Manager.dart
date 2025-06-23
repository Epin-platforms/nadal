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

      // 🔧 Apple에서 제공하는 정보만 사용 (추가 정보 요청 금지)
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
      print('🍎 Apple givenName: ${appleCredential.givenName}');
      print('🍎 Apple familyName: ${appleCredential.familyName}');
      print('🍎 Firebase Email: ${user.email}');

      // 🔧 Apple에서 제공하는 정보만 사용 (가이드라인 4.0 준수)
      // Apple에서 이름 정보를 제공한 경우에만 업데이트
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final String displayName = '${appleCredential.givenName ?? ''}${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          print('✅ Apple에서 제공한 displayName 적용: $displayName');
        }
      } else {
        // Apple에서 이름을 제공하지 않은 경우 기본값 설정 (추가 요청 없이)
        if (user.displayName == null || user.displayName!.isEmpty) {
          // 🔧 사용자에게 추가 정보를 요청하지 않고 기본값 사용
          await user.updateDisplayName('Apple 사용자');
          print('✅ Apple 기본 displayName 적용');
        }
      }

      // 🔧 이메일 처리 - Apple에서 제공한 정보만 사용
      if (appleCredential.email != null && appleCredential.email!.isNotEmpty) {
        try {
          // Apple에서 제공한 이메일이 있으면 사용
          await user.updateEmail(appleCredential.email!);
          print('✅ Apple에서 제공한 이메일 적용: ${appleCredential.email}');
        } catch (emailError) {
          print('이메일 업데이트 실패 (무시): $emailError');
        }
      } else {
        // 🔧 Apple에서 이메일을 제공하지 않은 경우
        // 사용자에게 추가 입력을 요구하지 않고 Firebase의 기본 이메일 사용
        print('Apple에서 이메일을 제공하지 않음 - Firebase 기본 이메일 사용');
      }

      // 🔧 Firebase 사용자 정보 새로고침
      await user.reload();

      // 🔧 잠시 대기 후 다시 새로고침 (안정성 확보)
      await Future.delayed(const Duration(milliseconds: 500));
      await user.reload();

      print('✅ Apple 로그인 완료 - 추가 정보 요청 없이 진행');

    } catch (e) {
      print('Apple 사용자 정보 업데이트 실패: $e');
      // 🔧 실패해도 로그인은 계속 진행 (Apple 가이드라인 준수)
    }
  }

  // 🔧 Apple 로그인 후 사용자 정보 검증 (필요시 사용)
  Future<Map<String, String?>> getAppleUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    };
  }
}