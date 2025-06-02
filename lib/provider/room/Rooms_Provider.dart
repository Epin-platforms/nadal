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

  // ✅ null 안전한 방 목록 가져오기
  List<MapEntry<int, Map<dynamic, dynamic>>> getRoomsList(BuildContext context) =>
      _getRoomsList(context);

  // ✅ 안전한 방 목록 정렬
  List<MapEntry<int, Map<dynamic, dynamic>>> _getRoomsList(BuildContext context) {
    // _rooms가 null이거나 비어있는 경우 빈 리스트 반환
    if (_rooms == null || _rooms!.isEmpty) {
      return <MapEntry<int, Map<dynamic, dynamic>>>[];
    }

    try {
      final chatProvider = Provider.of<ChatProvider>(context);
      final List<MapEntry<int, Map<dynamic, dynamic>>> list = _rooms!.entries.toList();

      list.sort((a, b) {
        final roomAId = a.key;
        final roomBId = b.key;

        // ✅ 안전한 시간 가져오기 - null 체크 강화
        DateTime timeA = DateTime.fromMillisecondsSinceEpoch(0);
        DateTime timeB = DateTime.fromMillisecondsSinceEpoch(0);

        try {
          final latestChatA = chatProvider.latestChatTime(roomAId);
          if (latestChatA?.createAt != null) {
            timeA = latestChatA!.createAt;
          }
        } catch (e) {
          // 개별 방의 채팅 시간 가져오기 실패시 기본값 유지
          print('roomAId $roomAId 채팅 시간 가져오기 실패: $e');
        }

        try {
          final latestChatB = chatProvider.latestChatTime(roomBId);
          if (latestChatB?.createAt != null) {
            timeB = latestChatB!.createAt;
          }
        } catch (e) {
          // 개별 방의 채팅 시간 가져오기 실패시 기본값 유지
          print('roomBId $roomBId 채팅 시간 가져오기 실패: $e');
        }

        return timeB.compareTo(timeA); // 최신순 내림차순 정렬
      });

      return list;
    } catch (e) {
      print('_getRoomsList 에러: $e');
      // 에러 발생시 정렬하지 않은 원본 리스트 반환
      return _rooms!.entries.toList();
    }
  }

}