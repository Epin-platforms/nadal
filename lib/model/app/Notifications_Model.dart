class NotificationModel{
  int notificationId;
  String uid;
  String? title;
  String? subTitle;
  String? routing;
  DateTime createAt;
  bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.uid,
    required this.routing,
    required this.createAt,
    this.title,
    this.subTitle,
    required this.isRead,
  });

  factory NotificationModel.fromJson({required Map<String, dynamic> json}){
    return NotificationModel(
        notificationId: json['notificationId'],
        title: json['title'],
        uid: json['uid'],
        subTitle: json['subTitle'],
        routing: json['routing'],
        createAt: DateTime.parse(json['createAt']).toLocal(),
        isRead: json['readState'] == 1 ? true : false,
    );
  }
}