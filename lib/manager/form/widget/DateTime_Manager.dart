class DateTimeManager{
  /// MariaDB DateTime을 UTC로 파싱 후 로컬 시간으로 변환
  static DateTime parseUtcToLocal(String dateTimeString) {
    // UTC 표시가 없으면 'Z'를 추가하여 UTC로 강제 인식
    String utcString = dateTimeString.endsWith('Z')
        ? dateTimeString
        : '${dateTimeString}Z';

    return DateTime.parse(utcString).toLocal();
  }

  /// 안전한 DateTime 파싱 (null 처리 포함)
  static DateTime? parseUtcToLocalSafe(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return parseUtcToLocal(dateTimeString);
    } catch (e) {
      print('DateTime 파싱 오류: $e');
      return null;
    }
  }
}