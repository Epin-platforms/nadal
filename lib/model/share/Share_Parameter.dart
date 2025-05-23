class ShareParameter{
  final String title;
  final String subTitle;
  final String? link;
  final String? imageUrl;
  final String routing;

  ShareParameter({
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.subTitle,
    required this.routing
  });


  toMap(){
    return {
      'title' : title,
      'subTitle' : subTitle,
      'link' : link,
      'imageUrl' : imageUrl
    };
  }
}