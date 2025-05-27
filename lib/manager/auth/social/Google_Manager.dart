import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../project/Import_Manager.dart';

class GoogleManager {
  static GoogleSignIn? _googleSignIn;

  static GoogleSignIn get _instance {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      signInOption: SignInOption.standard,
    );
    return _googleSignIn!;
  }

  Future<void> googleLogin() async {
    AppRoute.pushLoading();

    try {
      // 기존 세션 정리
      await _instance.signOut();

      final GoogleSignInAccount? googleUser = await _instance.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 토큰 검증
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 사용자 정보 업데이트 (안전하게)
      await _updateUserInfo(userCredential, googleUser);

    } on PlatformException catch (e) {
      // iOS/Android 플랫폼 에러
      DialogManager.errorHandler('로그인 중 오류가 발생했습니다: ${e.message}');
    } on FirebaseAuthException catch (e) {
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    } on Exception catch (e) {
      DialogManager.errorHandler('Google 로그인에 실패했습니다');
      print('Google 로그인 오류: $e');
    } catch (e) {
      DialogManager.errorHandler('예상치 못한 오류가 발생했습니다');
      print('Google 로그인 예외: $e');
    } finally {
      AppRoute.popLoading();
    }
  }

  Future<void> _updateUserInfo(UserCredential userCredential, GoogleSignInAccount googleUser) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      // displayName 업데이트
      if (googleUser.displayName != null && user.displayName != googleUser.displayName) {
        await user.updateDisplayName(googleUser.displayName);
      }

      // 이메일은 credential을 통해 이미 설정되므로 별도 업데이트 불필요
      // verifyBeforeUpdateEmail은 기존 사용자만 사용 가능하므로 제거

      // 프로필 사진 업데이트
      if (googleUser.photoUrl != null && user.photoURL != googleUser.photoUrl) {
        await user.updatePhotoURL(googleUser.photoUrl);
      }

      // 사용자 정보 새로고침
      await user.reload();

    } catch (e) {
      print('Google 사용자 정보 업데이트 실패: $e');
      // 로그인은 성공했으므로 에러 다이얼로그는 표시하지 않음
    }
  }

  Future<void> unLink() async {
    try {
      await _instance.signOut();
      await _instance.disconnect();
    } catch (e) {
      print('Google 계정 연결 해제 실패: $e');
      // 에러가 발생해도 Firebase 로그아웃은 진행되도록 함
    }
  }
}