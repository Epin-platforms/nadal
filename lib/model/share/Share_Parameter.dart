class ShareParameter {
  final String title;
  final String subTitle;
  final String? link;
  final String? imageUrl;
  final String routing;

  ShareParameter({
    required this.title,
    this.link,
    this.imageUrl,
    required this.subTitle,
    required this.routing,
  });

  // 안전한 복사 생성자
  ShareParameter copyWith({
    String? title,
    String? subTitle,
    String? link,
    String? imageUrl,
    String? routing,
  }) {
    return ShareParameter(
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      link: link ?? this.link,
      imageUrl: imageUrl ?? this.imageUrl,
      routing: routing ?? this.routing,
    );
  }

  // 데이터 검증
  bool get isValid {
    return title.isNotEmpty && subTitle.isNotEmpty && routing.isNotEmpty;
  }

  // 라우팅 경로 정규화
  String get normalizedRouting {
    if (routing.isEmpty) return '';

    // 앞에 슬래시가 없으면 추가
    if (!routing.startsWith('/')) {
      return '/$routing';
    }
    return routing;
  }

  // 안전한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subTitle': subTitle,
      'link': link,
      'imageUrl': imageUrl,
      'routing': normalizedRouting,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Map에서 안전한 생성
  factory ShareParameter.fromMap(Map<String, dynamic> map) {
    return ShareParameter(
      title: map['title']?.toString() ?? '',
      subTitle: map['subTitle']?.toString() ?? '',
      link: map['link']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      routing: map['routing']?.toString() ?? '',
    );
  }

  // 디버그용 문자열 표현
  @override
  String toString() {
    return 'ShareParameter{title: $title, subTitle: $subTitle, link: $link, imageUrl: $imageUrl, routing: $routing}';
  }

  // 동등성 비교
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareParameter &&
        other.title == title &&
        other.subTitle == subTitle &&
        other.link == link &&
        other.imageUrl == imageUrl &&
        other.routing == routing;
  }

  @override
  int get hashCode {
    return title.hashCode ^
    subTitle.hashCode ^
    link.hashCode ^
    imageUrl.hashCode ^
    routing.hashCode;
  }
}