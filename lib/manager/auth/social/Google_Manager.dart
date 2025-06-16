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
        AppRoute.popLoading();
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

      // 🔧 사용자 정보 업데이트 (이메일 포함)
      await _updateUserInfo(userCredential, googleUser);

      AppRoute.popLoading();
    } on PlatformException catch (e) {
      AppRoute.popLoading();
      // iOS/Android 플랫폼 에러
      DialogManager.errorHandler('로그인 중 오류가 발생했습니다: ${e.message}');
    } on FirebaseAuthException catch (e) {
      AppRoute.popLoading();
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    } on Exception catch (e) {
      AppRoute.popLoading();
      DialogManager.errorHandler('Google 로그인에 실패했습니다');
      print('Google 로그인 오류: $e');
    } catch (e) {
      AppRoute.popLoading();
      DialogManager.errorHandler('예상치 못한 오류가 발생했습니다');
      print('Google 로그인 예외: $e');
    }
  }

  Future<void> _updateUserInfo(UserCredential userCredential, GoogleSignInAccount googleUser) async {
    try {
      final user = userCredential.user;
      if (user == null) return;

      // 🔧 이메일 우선 업데이트 (구글 계정 이메일 보장)
      if (googleUser.email.isNotEmpty && user.email != googleUser.email) {
        try {
          // 신규 사용자의 경우 updateEmail 사용
          if (user.metadata.creationTime != null &&
              user.metadata.lastSignInTime != null &&
              user.metadata.creationTime!.millisecondsSinceEpoch ==
                  user.metadata.lastSignInTime!.millisecondsSinceEpoch) {
            // 첫 로그인인 경우
            await user.updateEmail(googleUser.email);
          }
        } catch (emailError) {
          print('이메일 업데이트 실패 (무시): $emailError');
          // 이메일 업데이트 실패해도 로그인은 계속 진행
        }
      }

      // displayName 업데이트
      if (googleUser.displayName != null && user.displayName != googleUser.displayName) {
        await user.updateDisplayName(googleUser.displayName);
      }

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