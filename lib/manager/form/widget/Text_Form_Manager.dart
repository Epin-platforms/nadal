
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TextFormManager{
  static String chatCreateAt(DateTime createAt){
    final isAm = createAt.hour < 12;
    return '${isAm ? '오전' : '오후'} ${DateFormat('hh:mm').format(createAt)}';
  }

  static String profileText(String? nickName, String? name, int? birthYear, String? gender, {bool useNickname = true}){

    if(name == null){
      if(nickName == null) return '(알수없음)';
      return nickName;
    }

    String birth = (birthYear ?? '').toString();
    String gender0 = gender == 'M' ? '남' : gender == 'F'  ? '여' : '';

    return useNickname  ? name : '$name/$birth/$gender0';
  }

  /// 초성 우선 한글 정렬
  static int compareKorean(String a, String b) {
    final aChar = a.characters.first;
    final bChar = b.characters.first;

    final aCode = aChar.codeUnitAt(0);
    final bCode = bChar.codeUnitAt(0);

    // 한글 범위 체크
    if (_isHangul(aCode) && _isHangul(bCode)) {
      final aInitial = _getInitialSound(aCode);
      final bInitial = _getInitialSound(bCode);

      if (aInitial != bInitial) {
        return aInitial.compareTo(bInitial);
      }
      return a.compareTo(b);
    }

    return a.compareTo(b);
  }

  /// 한글 초성 추출
  static String _getInitialSound(int codeUnit) {
    const initialSounds = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
      'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];

    final base = 0xAC00;
    final cho = ((codeUnit - base) ~/ (21 * 28));

    return initialSounds[cho];
  }

  /// 한글 범위 체크
  static bool _isHangul(int codeUnit) {
    return codeUnit >= 0xAC00 && codeUnit <= 0xD7A3;
  }


  //요일 반환
  static String returnWeek({required DateTime date}){
    return date.weekday == 1 ? '월' : date.weekday == 2 ? '화' : date.weekday == 3 ? '수' : date.weekday == 4 ? '목' : date.weekday == 5 ? '금' : date.weekday == 6 ? '토' : '일';
  }


  static String createFormToScheduleDate(DateTime date, bool isAllDay){
    final isAm = date.hour < 12;
    if(DateTime.now().year != date.year){
      return '${DateFormat('yyyy년\nM월 d일').format(date)} (${returnWeek(date: date)})${isAllDay ? '' : '\n\n${isAm? '오전' : '오후'} ${DateFormat('h:mm').format(date)}'}';
    }else{
      return '${DateFormat('M월 d일').format(date)} (${returnWeek(date: date)})${isAllDay ? '' : '\n\n${isAm? '오전' : '오후'} ${DateFormat('h:mm').format(date)}'}';
    }
  }


  static String? stateToText(int? state){
    switch(state){
      case 0 : return '모집중';
      case 1 : return '모집종료';
      case 2 : return '추첨중';
      case 3 : return '게임중';
      case 4 : return '종료';
      default : return null;
    }
  }

  static String timeAgo({required dynamic item}) {
    DateTime? date;

    if(item is String){
      date = DateTime.parse(item).toLocal();
    }else{
      date = item;
    }

    final now = DateTime.now();
    final difference = now.difference(date!);

    if (difference.inDays >= 365) {
      return '${difference.inDays ~/ 365}년 전';
    } else if (difference.inDays >= 30) {
      return '${difference.inDays ~/ 30}달 전';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes >= 5) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }


  static String formatNumberWithCommas(int number) {
    String numStr = number.toString(); // 숫자를 문자열로 변환
    StringBuffer formatted = StringBuffer();

    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      formatted.write(numStr[i]);
      if (count % 3 == 0 && i != 0) {
        formatted.write(',');
      }
    }

    return formatted.toString().split('').reversed.join(); // 문자열 뒤집기
  }


  static String fromToDate(dynamic from, dynamic to, {bool isAllDay = false}){
    DateTime fromDate = (from is String) ? DateTime.parse(from) : from;
    DateTime toDate = (to is String) ? DateTime.parse(to) : to;

    if(isAllDay){
      final String allDayForm = DateTime.now().year == fromDate.year ? 'M월 d일 (E)' : 'yyyy년 M월 d일 (E)';
      return '${DateFormat(allDayForm, 'ko').format(fromDate)} 종일';
    }else{
      final String form = DateTime.now().year == fromDate.year ? 'M월 d일 (E) H:mm' : 'yyyy년 M월 d일 (E) H:mm';
      final String toForm = fromDate.year == toDate.year && fromDate.month == toDate.month && fromDate.day == toDate.day ? 'H:mm' : form;
      return '${DateFormat(form, 'ko').format(fromDate)} ~ ${DateFormat(toForm, 'ko').format(toDate)} ';
    }
  }

  static String formToLocal(String local){
    if(local.length > 4){
      return local.substring(0,2);
    }else if(local.length == 3) {
      return local;
    }else{
      return '${local.substring(0,1)}${local.substring(2,3)}';
    }
  }

  static String encodeQueryParam(String input) {
    return Uri.encodeComponent(input.trim());
  }
}