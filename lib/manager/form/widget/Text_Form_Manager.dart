import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';

class TextFormManager {
  // 채팅 시간 포맷
  static String chatCreateAt(DateTime createAt) {
    final isAm = createAt.hour < 12;
    return '${isAm ? '오전' : '오후'} ${DateFormat('hh:mm').format(createAt)}';
  }

  // 프로필 텍스트 생성
  static String profileText(String? nickName, String? name, int? birthYear, String? gender, {bool useNickname = true}) {
    if (useNickname) {
      return nickName ?? '(알수없음)';
    } else {
      if (name == null) {
        return '(알수없음)';
      }
      String birth = (birthYear ?? '').toString();
      String gender0 = gender == 'M' ? '남' : gender == 'F' ? '여' : '';
      return '$name/$birth/$gender0';
    }
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

  // 요일 반환
  static String returnWeek({required DateTime date}) {
    return date.weekday == 1 ? '월' :
    date.weekday == 2 ? '화' :
    date.weekday == 3 ? '수' :
    date.weekday == 4 ? '목' :
    date.weekday == 5 ? '금' :
    date.weekday == 6 ? '토' : '일';
  }

  // 스케줄 날짜 포맷
  static String createFormToScheduleDate(DateTime date, bool isAllDay) {
    final isAm = date.hour < 12;
    if (DateTime.now().year != date.year) {
      return '${DateFormat('yyyy년\nM월 d일').format(date)} (${returnWeek(date: date)})${isAllDay ? '' : '\n\n${isAm ? '오전' : '오후'} ${DateFormat('h:mm').format(date)}'}';
    } else {
      return '${DateFormat('M월 d일').format(date)} (${returnWeek(date: date)})${isAllDay ? '' : '\n\n${isAm ? '오전' : '오후'} ${DateFormat('h:mm').format(date)}'}';
    }
  }

  // 상태 텍스트 변환
  static String? stateToText(int? state) {
    switch (state) {
      case 0: return '모집중';
      case 1: return '모집종료';
      case 2: return '추첨중';
      case 3: return '게임중';
      case 4: return '종료';
      default: return null;
    }
  }

  // 시간 경과 표시
  static String timeAgo({required dynamic item}) {
    DateTime? date;

    // createAt은 timeStamp이므로 local로 변경
    if (item is String) {
      date = DateTimeManager.parseUtcToLocalSafe(item);
    } else {
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

  // 숫자 콤마 포맷
  static String formatNumberWithCommas(int number) {
    String numStr = number.toString();
    StringBuffer formatted = StringBuffer();

    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      formatted.write(numStr[i]);
      if (count % 3 == 0 && i != 0) {
        formatted.write(',');
      }
    }

    return formatted.toString().split('').reversed.join();
  }

  // 기간 표시
  static String fromToDate(dynamic from, dynamic to, {bool isAllDay = false}) {
    DateTime fromDate = (from is String) ? DateTime.parse(from) : from;
    DateTime toDate = (to is String) ? DateTime.parse(to) : to;

    if (isAllDay) {
      final String allDayForm = DateTime.now().year == fromDate.year ? 'M월 d일 (E)' : 'yyyy년 M월 d일 (E)';
      return '${DateFormat(allDayForm, 'ko').format(fromDate)} 종일';
    } else {
      final String form = DateTime.now().year == fromDate.year ? 'M월 d일 (E) H:mm' : 'yyyy년 M월 d일 (E) H:mm';
      final String toForm = fromDate.year == toDate.year && fromDate.month == toDate.month && fromDate.day == toDate.day ? 'H:mm' : form;
      return '${DateFormat(form, 'ko').format(fromDate)} ~ ${DateFormat(toForm, 'ko').format(toDate)} ';
    }
  }

  // 지역명 포맷
  static String formToLocal(String local) {
    if (local.length > 4) {
      return local.substring(0, 2);
    } else if (local.length == 3) {
      return local;
    } else {
      return '${local.substring(0, 1)}${local.substring(2, 3)}';
    }
  }

  // === 검색 관련 기능 (단순화) ===

  // URL 안전한 쿼리 파라미터 인코딩
  static String encodeQueryParam(String text) {
    if (text.isEmpty) return '';

    try {
      // 기본 정제
      final sanitized = text.trim();
      if (sanitized.isEmpty) return '';

      // 길이 제한
      final limited = sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;

      // URI 인코딩 (특수문자 포함)
      return Uri.encodeComponent(limited);
    } catch (e) {
      debugPrint('쿼리 파라미터 인코딩 실패: $e');
      return '';
    }
  }

  // 검색어 검증 (매우 기본적인 검증만)
  static bool isValidSearchText(String text) {
    if (text.isEmpty) return false;

    final trimmed = text.trim();

    // 길이 검증만 (2-100자)
    if (trimmed.length < 2 || trimmed.length > 100) return false;

    // 공백만 있는지만 체크
    if (RegExp(r'^[\s]+$').hasMatch(trimmed)) return false;

    return true;
  }

  // 텍스트 정규화
  static String normalizeText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // 연속된 공백을 하나로
        .replaceAll(RegExp(r'[\r\n\t]'), ' ') // 개행문자를 공백으로
        .replaceAll('...', ''); //ellipsis 제거
  }

  // 검색어 정제 (# 허용)
  static String sanitizeSearchText(String text) {
    if (text.isEmpty) return '';

    final normalized = normalizeText(text);
    return normalized.length > 100 ? normalized.substring(0, 100) : normalized;
  }

  //공백제거
  static String removeSpace(String text){
    return text.replaceAll(' ', '').replaceAll('\n', '');
  }
}