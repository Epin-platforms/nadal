import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../project/Import_Manager.dart';

class AppleManager {
  final appleSaveNameKey = "epin.nadal.apple.name";
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

      // 🔧 Apple에서 제공하는 정보만 사용 (추가 정보 요청 절대 금지)
      await _updateAppleUserInfo(userCredential, appleCredential);

      // 🔧 Apple 이메일 정보 별도 저장 (필요한 경우)
      if (appleCredential.email != null && appleCredential.email!.isNotEmpty) {
        await saveAppleEmailInfo(appleCredential.email);
      }

      AppRoute.popLoading();
    } on SignInWithAppleAuthorizationException catch (e) {
      AppRoute.popLoading();
      if (e.code == AuthorizationErrorCode.canceled) {
        return; // 사용자 취소는 조용히 처리
      }
      DialogManager.errorHandler('Apple 로그인 인증에 실패했습니다');
      print('Apple 인증 오류: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      AppRoute.popLoading();
      FirebaseAuthExceptionHandler.firebaseHandler(e.code);
    } catch (e) {
      AppRoute.popLoading();
      DialogManager.errorHandler('Apple 로그인에 실패했습니다');
      print('Apple 로그인 오류: $e');
    }
  }

  Future<void> _updateAppleUserInfo(UserCredential userCredential, AuthorizationCredentialAppleID appleCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();

      print('🍎 Apple 로그인 - 가이드라인 4.0 준수 모드');
      print('🍎 Apple Email: ${appleCredential.email}');
      print('🍎 Apple givenName: ${appleCredential.givenName}');
      print('🍎 Apple familyName: ${appleCredential.familyName}');
      print('🍎 Firebase Email: ${user.email}');

      // 🔧 1. 이름 처리 - Apple에서 제공한 정보만 사용
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final String displayName = '${appleCredential.givenName ?? ''}${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          prefs.setString(appleSaveNameKey, displayName);
          await user.updateDisplayName(displayName);
          print('✅ Apple 제공 이름 적용: $displayName');
        }
      } else {
        // Apple에서 이름을 제공하지 않은 경우 - 기본값으로 처리
        final name = prefs.getString(appleSaveNameKey);
        if (user.displayName == null || user.displayName!.isEmpty) {
          await user.updateDisplayName(name ?? 'Apple 사용자');
          print('✅ Apple 기본 이름 적용');
        }
      }

      // 🔧 2. 이메일 처리 - deprecated updateEmail() 제거
      // Apple 가이드라인 4.0: 추가 이메일 확인 요청 금지
      // Firebase에서 자동으로 설정하는 이메일 정보 사용
      if (appleCredential.email != null && appleCredential.email!.isNotEmpty) {
        print('✅ Apple 제공 이메일 확인: ${appleCredential.email}');
        // 🚫 updateEmail() 사용 금지 - deprecated이며 Apple 가이드라인 위배
        // 🚫 verifyBeforeUpdateEmail() 사용 금지 - 사용자에게 추가 확인 요청 (가이드라인 4.0 위배)

        // Firebase에서 자동으로 설정한 이메일 정보를 그대로 사용
        print('Firebase가 자동 설정한 이메일 사용: ${user.email}');
      } else {
        // Apple에서 이메일을 제공하지 않은 경우 - 강제하지 않음
        print('✅ Apple에서 이메일 미제공 - Firebase 기본값 사용: ${user.email}');
      }

      // 🔧 3. 사용자 정보 새로고침
      await user.reload();
      await Future.delayed(const Duration(milliseconds: 500));
      await user.reload();

      print('✅ Apple 로그인 완료 - 가이드라인 4.0 완전 준수');
      print('최종 사용자 정보:');
      print('  - UID: ${user.uid}');
      print('  - Email: ${user.email}');
      print('  - DisplayName: ${user.displayName}');

    } catch (e) {
      print('Apple 사용자 정보 업데이트 실패: $e');
      // 🔧 실패해도 로그인은 계속 진행 (Apple 가이드라인 준수)
    }
  }

  // 🔧 Apple 로그인 후 사용자 정보 확인 (디버깅용)
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

  // 🔧 Apple 이메일 정보 별도 저장 (필요한 경우)
  Future<void> saveAppleEmailInfo(String? appleEmail) async {
    if (appleEmail == null || appleEmail.isEmpty) return;

    try {
      // SharedPreferences나 Firestore에 Apple 이메일 정보 저장
      // 이는 Firebase Auth의 이메일과 별개로 관리
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apple_provided_email', appleEmail);
      print('Apple 제공 이메일 별도 저장: $appleEmail');
    } catch (e) {
      print('Apple 이메일 정보 저장 실패: $e');
    }
  }

  // 🔧 저장된 Apple 이메일 정보 조회
  Future<String?> getSavedAppleEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('apple_provided_email');
    } catch (e) {
      print('Apple 이메일 정보 조회 실패: $e');
      return null;
    }
  }

  // 🔧 Apple 로그인 연결 해제 (제한적)
  Future<void> unLink() async {
    try {
      print('🍎 Apple 연결 해제 시작');

      // 1. SharedPreferences에서 Apple 관련 데이터 삭제
      await _clearAppleLocalData();

      // 2. Firebase에서 Apple 제공자 해제 시도
      await _unlinkAppleFromFirebase();

      print('✅ Apple 로컬 연결 해제 완료');

    } catch (e) {
      print('❌ Apple 연결 해제 실패: $e');
      // 실패해도 로그아웃 프로세스는 계속 진행
    }
  }

  // 🔧 Apple 로컬 데이터 완전 삭제
  Future<void> _clearAppleLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Apple 관련 모든 로컬 데이터 삭제
      await prefs.remove('apple_provided_email');

      print('✅ Apple 로컬 데이터 삭제 완료');
    } catch (e) {
      print('❌ Apple 로컬 데이터 삭제 실패: $e');
    }
  }

  // 🔧 Firebase에서 Apple 제공자 연결 해제
  Future<void> _unlinkAppleFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Apple 제공자가 연결되어 있는지 확인
      final hasAppleProvider = user.providerData.any(
              (provider) => provider.providerId == 'apple.com'
      );

      if (hasAppleProvider) {
        // Firebase에서 Apple 제공자 연결 해제
        await user.unlink('apple.com');
        print('✅ Firebase Apple 제공자 연결 해제 완료');
      }
    } catch (e) {
      print('❌ Firebase Apple 연결 해제 실패: $e');
      // 이미 해제되었거나 다른 이유로 실패 - 무시하고 계속 진행
    }
  }
}