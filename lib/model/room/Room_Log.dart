import '../../manager/form/widget/DateTime_Manager.dart';

class RoomLog{
  int logId;
  int roomId;
  String? uid;
  String? name;
  String action;
  DateTime createAt;

  RoomLog({
    required this.logId,
    required this.roomId,
    required this.uid,
    this.name,
    required this.action,
    required this.createAt
  });


  factory RoomLog.fromJson(Map<String, dynamic> json){
    return RoomLog(
        logId: json['logId'],
        roomId: json['roomId'],
        uid: json['uid'],
        name : json['displayName'],
        action: json['action'],
        createAt: DateTimeManager.parseUtcToLocalSafe(json['createAt']) ?? DateTime.now()
    );
  }
}