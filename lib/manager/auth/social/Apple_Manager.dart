import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../project/Import_Manager.dart';

class AppleManager{
  Future<void> appleLogin() async {
    AppRoute.pushLoading();
    try{
      final AuthorizationCredentialAppleID appleCredential =  await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase 로그인
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // ✅ 최초 로그인 시 이메일과 이름 저장
      if (appleCredential.email != null && appleCredential.givenName != null) {
        await userCredential.user!.updateDisplayName(
          '${appleCredential.givenName}${appleCredential.familyName}',
        );
        await userCredential.user!.verifyBeforeUpdateEmail(appleCredential.email!);
      }else{
        print('애플 이메일 저장 실패');
      }

    }on FirebaseAuthException catch (e) {
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    }finally{
      AppRoute.popLoading();
    }
  }


}