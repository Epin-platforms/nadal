import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/chat/Chat.dart';

class RoomsProvider extends ChangeNotifier{
  Map<int,Map>? _rooms;
  Map<int,Map>? get rooms => _rooms;

  Future<void> roomInitialize() async{
    try{
      final response = await serverManager.get('room/rooms');

      if(response.statusCode == 200 && response.data != null){
        final list = List<Map<String, dynamic>>.from(response.data);

        _rooms = {
          for (var room in list)
            if (room['roomId'] != null)
              room['roomId'] as int : room,
        };
      } else {
        _rooms = {};
      }
    } catch (e) {
      print('방 목록 초기화 오류: $e');
      _rooms = {};
    } finally{
      notifyListeners();
    }
  }

  Future<void> updateRoom(int roomId) async{
    try {
      if (_rooms == null) {
        await roomInitialize();
        return;
      }

      final updateAt = _rooms?[roomId]?['updateAt'];
      final res = await serverManager.get('room/reGet/$roomId?updateAt=$updateAt');

      if(res.statusCode == 200 && res.data != null){
        final roomData = res.data as Map<String, dynamic>;
        final updatedRoomId = roomData['roomId'] as int?;

        if (updatedRoomId != null) {
          _rooms![updatedRoomId] = roomData;
          notifyListeners();
        }
      }
    } catch (e) {
      print('방 업데이트 오류 (roomId: $roomId): $e');
    }
  }

  List<MapEntry<int, Map<dynamic, dynamic>>> getRoomsList(BuildContext context) =>
      _getRoomsList(context);

  List<MapEntry<int, Map<dynamic, dynamic>>> _getRoomsList(BuildContext context) {
    if (_rooms == null || _rooms!.isEmpty) {
      return <MapEntry<int, Map<dynamic, dynamic>>>[];
    }

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final List<MapEntry<int, Map<dynamic, dynamic>>> list = _rooms!.entries.toList();

      list.sort((a, b) {
        try {
          final roomAId = a.key;
          final roomBId = b.key;

          DateTime timeA = DateTime.fromMillisecondsSinceEpoch(0);
          DateTime timeB = DateTime.fromMillisecondsSinceEpoch(0);

          try {
            final latestChatA = chatProvider.latestChatTime(roomAId);
            if (latestChatA?.createAt != null) {
              timeA = latestChatA!.createAt;
            }
          } catch (e) {
            print('roomAId $roomAId 채팅 시간 가져오기 실패: $e');
          }

          try {
            final latestChatB = chatProvider.latestChatTime(roomBId);
            if (latestChatB?.createAt != null) {
              timeB = latestChatB!.createAt;
            }
          } catch (e) {
            print('roomBId $roomBId 채팅 시간 가져오기 실패: $e');
          }

          return timeB.compareTo(timeA);
        } catch (e) {
          print('방 정렬 비교 오류: $e');
          return 0;
        }
      });

      return list;
    } catch (e) {
      print('방 목록 정렬 오류: $e');
      return _rooms!.entries.toList();
    }
  }
}