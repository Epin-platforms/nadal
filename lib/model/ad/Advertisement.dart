class Advertisement{
  final int adId;
  final String title;
  final String imageUrl;
  final String link;
  final String advertiser;
  final int click;
  final int view;

  Advertisement({
    required this.adId,
    required this.title,
    required this.imageUrl,
    required this.link,
    required this.advertiser,
    required this.click,
    required this.view
  });

  factory Advertisement.fromJson(Map map){
    return Advertisement(
        adId: map['adId'],
        title: map['title'],
        link: map['link'],
        imageUrl: map['imageUrl'],
        advertiser: map['advertiser'],
        click: map['click'],
        view: map['view']
    );
  }
}