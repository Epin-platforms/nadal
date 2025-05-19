import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/chat/Chat.dart';


class RoomsProvider extends ChangeNotifier{
  //방에서는 방만 관리
  Map<int,Map>? _rooms;
  Map<int,Map>? get rooms => _rooms;

  //방정보 초기화중
  Future<void> roomInitialize() async{
    try{
      final response = await serverManager.get('room/rooms');

      if(response.statusCode == 200){
        final list = List<Map<String, dynamic>>.from(response.data);

        _rooms = {
          for (var room in list) room['roomId'] as int : room,
        };
      }
    }finally{
      notifyListeners();
    }
  }

  Future<void> updateRoom(int roomId) async{
    final updateAt = _rooms?[roomId]?['updateAt'];

    final res = await serverManager.get('room/reGet/$roomId?updateAt=$updateAt');

    if(res.statusCode == 200){
      _rooms![res.data['roomId']] = res.data;
      notifyListeners();
    }
  }

  List<MapEntry<int, Map<dynamic, dynamic>>> getRoomsList(context) => _getRoomsList(context);

  List<MapEntry<int, Map<dynamic, dynamic>>> _getRoomsList(BuildContext context){
    final chatProvider = Provider.of<ChatProvider>(context);
    final List<MapEntry<int, Map<dynamic, dynamic>>> list = _rooms!.entries.toList();

    list.sort((a, b) {
      final roomAId = a.key;
      final roomBId = b.key;

      final timeA = chatProvider.latestChatTime(roomAId)?.createAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = chatProvider.latestChatTime(roomBId)?.createAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return timeB.compareTo(timeA); // 최신순 내림차순 정렬
    });

    return list;
  }

}