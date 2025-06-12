import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/chat/Chat.dart';

class RoomsProvider extends ChangeNotifier{
  Map<int,Map>? _rooms;
  Map<int,Map>? get rooms => _rooms;

  Map<int, Map>? _quickRooms;
  Map<int, Map>? get quickRooms => _quickRooms;

  Future<void> roomInitialize() async{
    try{
      final response = await serverManager.get('room/rooms');

      if(response.statusCode == 200 && response.data != null){
        final list = List<Map<String, dynamic>>.from(response.data);
        final club = list.where((e)=> e['isOpen'] == 0).toList(); //0이면 false
        final quick = list.where((e)=> e['isOpen'] == 1).toList(); //1이면 오픈 채팅
        _rooms = {
          for (var room in club)
            if (room['roomId'] != null)
              room['roomId'] as int : room,
        };

        _quickRooms = {
          for (var room in quick)
            if (room['roomId'] != null)
              room['roomId'] as int : room,
        };
      } else {
        _rooms = {};
        _quickRooms = {};
      }
    } catch (e) {
      print('방 목록 초기화 오류: $e');
      _rooms = {};
      _quickRooms = {};
    } finally{
      notifyListeners();
    }
  }

  //
  // room 관련 기능들
  //
  Future<bool?> updateRoom(int roomId, {bool isOpenRoom = false}) async{
    bool isOpen = false;
    try {
      if (_rooms == null) {
        await roomInitialize();
        return null;
      }
      final updateAt = isOpenRoom ? _quickRooms?[roomId]?['updateAt'] : _rooms?[roomId]?['updateAt'];
      final res = await serverManager.get('room/reGet/$roomId?updateAt=$updateAt');

      if(res.statusCode == 200 && res.data != null){
        final roomData = res.data as Map<String, dynamic>;
        print('방데이터 불러오기 - $roomData');
        final updatedRoomId = roomData['roomId'] as int?;

        if (updatedRoomId != null) {
          isOpen = roomData['isOpen'] == 1;
          if(isOpen){
            _quickRooms![updatedRoomId] = roomData;
          }else{
            _rooms![updatedRoomId] = roomData;
          }
          notifyListeners();
        }
      }

      return isOpen;
    } catch (e) {
      print('방 업데이트 오류 (roomId: $roomId): $e');
    }
    return null;
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

  //
  // quick room 관련 기능들
  //
  List<MapEntry<int, Map<dynamic, dynamic>>> getQuickList(BuildContext context) => _getQuickList(context);

  List<MapEntry<int, Map<dynamic, dynamic>>> _getQuickList(BuildContext context) {
    if (_quickRooms == null || _quickRooms!.isEmpty) {
      return <MapEntry<int, Map<dynamic, dynamic>>>[];
    }

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final List<MapEntry<int, Map<dynamic, dynamic>>> list = _quickRooms!.entries.toList();

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
            print('_quickRooms $roomAId 채팅 시간 가져오기 실패: $e');
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