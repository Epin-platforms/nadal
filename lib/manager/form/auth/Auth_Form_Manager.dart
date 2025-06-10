class AuthFormManager{
  //연차로 변경
  static String careerDateToYearText(String? date){
    if(date == null){
      return '?년';
    }else{
      final career = DateTime.parse(date);
      final int year = DateTime.now().difference(career).inDays ~/ 365;
      return year == 0 ? '초보' : '$year년';
    }
  }

  //연차에서 데이트로 변경
  static String careerYearToDate(int year, int? month){
    final careerNow = DateTime(DateTime.now().year, month ?? DateTime.now().month, 1);
    final int days = year * 365;
    return careerNow.subtract(Duration(days: days)).toIso8601String();
  }

  //레벨 측정
  static double careerToLevel(int career){
    switch(career){
      case 0 : return 1.0;
      case 1 : return 2.0;
      case 2 : return 2.5;
      case 3 : return 3.0;
      case 4 : return 3.5;
      case 5 : return 3.5;
      case 6 : return 4.0;
      case 7 : return 4.0;
      case 8 : return 4.0;
      case 9 : return 4.5;
      case 10 : return 4.5;
      case 11 : return 4.5;
      case 12 : return 5.0;
      default : return 5.0;
    }
  }

  static String? phoneForm(String? number){
    return number?.replaceFirst('+82 ', '0').replaceAll('-', '');
  }
}