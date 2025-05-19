class GraderFormManager{

  static String intToGrade(int value){
    switch(value){
      case 0 : return '클럽장';
      case 1 : return '매니져';
      case 2 : return '정회원';
      default : return '신입';
    }
  }
}