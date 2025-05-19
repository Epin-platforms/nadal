import 'package:google_sign_in/google_sign_in.dart';

import '../../project/Import_Manager.dart';

class GoogleManager{
  Future<void> googleLogin() async {
    AppRoute.pushLoading();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile'
          ]
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      await FirebaseAuth.instance.signInWithCredential(credential);
    }on FirebaseAuthException catch (e) {
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    }finally{
      AppRoute.popLoading();
    }
  }

  //구글 계정 연결 종료
  Future<void> unLink() async{
    await GoogleSignIn().signOut();
  }
}