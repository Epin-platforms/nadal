import 'dart:convert';

import 'package:my_sports_calendar/manager/form/widget/DateTime_Manager.dart';

enum ChatType{
  text, image, schedule, removed
}

class Chat{
  //기본 채팅이 포함하는 내용 정보
  int chatId; //last chat id로 사용가능 //auto increase PK
  int roomId; //int  FK
  String uid; //보낸사람  //FK
  int? reply; //null이 아닐 경우 chatId로 접근해서 해당 채팅에 대한 답장 가능
  ChatType type; // -1 : log, 0: 기본 텍스트, 1: 이미지, 2: 스케줄, 3: 게임
  String? contents; //오직 텍스트만
  int? scheduleId;
  List<String>? images; //이미지 첨부일 경우 업로드한 이미지 path
  DateTime createAt;
  DateTime updateAt;

  //보낸 사용자의 정보 //방을 나간 사용자는 이름만 표시, 방에있는 사용자는 roomMember를 이용해 데이터 출력
  String? name;
  String? gender;
  int? birthYear;
  String? profileImage;

  //만약 채팅타입이, 스케줄일 경우
  String? title;
  DateTime? startDate;
  DateTime? endDate;
  String? tag;

  String? replyName;
  String? replyContents;
  int? replyType;

  Chat({
    required this.roomId,
    required this.chatId,
    required this.uid,
    required this.createAt,
    required this.updateAt,
    required this.type,
    this.reply,
    required this.contents,
    this.images,

    //추가적으로 긁어올거
    this.scheduleId,
    this.title,
    this.endDate,
    this.startDate,
    this.tag,

    this.name,
    this.profileImage,
    this.gender,
    this.birthYear,

    this.replyContents,
    this.replyName,
    this.replyType
  });


  factory Chat.fromJson({required Map<String,dynamic> json}){
    print(json['createAt']);
    final type = intToChatType(json['type']);
    final uid = json['uid'] ?? '-1';
    return Chat(
        chatId: json['chatId'] ,
        roomId: json['roomId'],
        uid: uid,
        type: type, //type == -1면 삭제된 메시지
        contents: json['contents'],
        images: json['images'] == null ? null : List<String>.from(jsonDecode(json['images'])),
        scheduleId: json['scheduleId'],
        createAt: DateTimeManager.parseUtcToLocalSafe(json['createAt']) ?? DateTime.now(),
        updateAt: DateTimeManager.parseUtcToLocalSafe(json['updateAt']) ?? DateTime.now(),
        title: json['title'],
        startDate: DateTimeManager.parseUtcToLocalSafe(json['startDate']),
        endDate: DateTimeManager.parseUtcToLocalSafe(json['endDate']),
        tag: json['tag'],
        name: uid == -1 ? '(알수없음)' : json['name'] ,//이름이 없다면 탈퇴한 사용자
        gender: uid == -1 ? '?' : json['gender'],
        birthYear: uid == -1 ? 0 : json['birthYear'],
        profileImage: json['profileImage'],
        reply: json['reply'],
        replyName: json['replyName'],
        replyContents: json['replyContents'],
        replyType: json['replyType']
    );
  }

  static ChatType intToChatType(int type){
    switch(type){
      case -1 : return ChatType.removed;
      case 1 : return ChatType.image;
      case 2 : return ChatType.schedule;
      default : return ChatType.text;
    }
  }
}