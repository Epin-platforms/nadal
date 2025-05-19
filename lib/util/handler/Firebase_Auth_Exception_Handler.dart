import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';

class FirebaseAuthExceptionHandler{

  static firebaseHandler(String code){
    String comment = '알 수 없는 오류가 발생했어요.';

    switch (code) {
      case 'permission-denied':
        comment = '보안 규칙에 위반된 계정입니다.';
      case 'user-not-found':
        comment = '존재하지 않는 계정입니다.';
      case 'email-already-in-use':
        comment = '이미 가입이 완료된 계정입니다.';
      case 'too-many-requests':
        comment = '잠시 후 다시 시도해주세요.';
      case 'user-disabled':
        comment = '사용이 중단된 계정입니다.';
      case 'account-exists-with-different-credential':
        comment = '다른 소셜로 가입된 계정입니다.';
    }

    DialogManager.errorHandler(comment);
  }
}