enum TargetType {
  chat, user, schedule, room
}

class ReportModel{
   final String reason;
   final TargetType target_type;
   final dynamic target_id;
   final String? description;

   ReportModel({
    this.description,
    required this.reason,
    required this.target_id,
    required this.target_type
  });

   toMap(){
     Map<String, dynamic> map = {
       'reason' : reason,
       'target_type' : switchToString(target_type),
       'target_id' : target_id,
     };

     if(description != null){
       map.addAll({'description' : description});
     }
     return map;
   }

   String switchToString(TargetType target){
     switch(target){
       case TargetType.room :  return 'room';
       case TargetType.chat : return 'chat';
       case TargetType.schedule : return 'schedule';
       case TargetType.user : return 'user';
     }
   }

   static TargetType switchToType(String? value){
     switch(value){
       case 'room' : return TargetType.room;
       case 'chat' : return TargetType.chat;
       case 'schedule' : return TargetType.schedule;
       case 'user' : return TargetType.user;
       default : return TargetType.user;
     }
   }
}