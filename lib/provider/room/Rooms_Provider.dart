import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class RoomsProvider extends ChangeNotifier {
  // 방 데이터
  Map<int, Map>? _rooms;           // 일반 클럽 (isOpen = 0)
  Map<int, Map>? _quickRooms;      // 번개챗 (isOpen = 1)

  // Getters
  Map<int, Map>? get rooms => _rooms;
  Map<int, Map>? get quickRooms => _quickRooms;

  // 방 목록 초기화
  Future<void> roomInitialize() async {
    try {
      print('🚀 방 목록 초기화 시작');

      final response = await serverManager.get('room/rooms');

      if (response.statusCode == 200 && response.data != null) {
        final allRooms = List<Map<String, dynamic>>.from(response.data);

        // isOpen 값에 따라 분류
        final clubRooms = allRooms.where((room) => room['isOpen'] == 0).toList();
        final quickChatRooms = allRooms.where((room) => room['isOpen'] == 1).toList();

        // Map으로 변환 (roomId를 키로 사용)
        _rooms = {
          for (var room in clubRooms)
            if (room['roomId'] != null)
              room['roomId'] as int: room,
        };

        _quickRooms = {
          for (var room in quickChatRooms)
            if (room['roomId'] != null)
              room['roomId'] as int: room,
        };

        print('✅ 방 목록 초기화 완료');
        print('- 일반 클럽: ${_rooms!.length}개');
        print('- 번개챗: ${_quickRooms!.length}개');
      } else {
        print('⚠️ 방 목록이 비어있음');
        _rooms = {};
        _quickRooms = {};
      }
    } catch (e) {
      print('❌ 방 목록 초기화 오류: $e');
      _rooms = {};
      _quickRooms = {};
    } finally {
      notifyListeners();
    }
  }

  // 특정 방 정보 업데이트
  Future<bool?> updateRoom(int roomId, {bool isOpenRoom = false}) async {
    try {
      if (_rooms == null || _quickRooms == null) {
        await roomInitialize();
        return null;
      }

      // 업데이트할 방 찾기
      final targetRooms = isOpenRoom ? _quickRooms! : _rooms!;
      final currentRoom = targetRooms[roomId];
      final updateAt = currentRoom?['updateAt'];

      print('🔄 방 업데이트 요청: roomId=$roomId, updateAt=$updateAt');

      final res = await serverManager.get('room/reGet/$roomId?updateAt=$updateAt');

      if (res.statusCode == 200 && res.data != null) {
        final roomData = res.data as Map<String, dynamic>;
        final updatedRoomId = roomData['roomId'] as int?;

        if (updatedRoomId != null) {
          final isOpen = roomData['isOpen'] == 1;

          // 올바른 맵에 저장
          if (isOpen) {
            _quickRooms![updatedRoomId] = roomData;
            // 혹시 일반 클럽에 있었다면 제거
            _rooms!.remove(updatedRoomId);
          } else {
            _rooms![updatedRoomId] = roomData;
            // 혹시 번개챗에 있었다면 제거
            _quickRooms!.remove(updatedRoomId);
          }

          notifyListeners();
          print('✅ 방 업데이트 완료: roomId=$roomId, isOpen=$isOpen');
          return isOpen;
        }
      }

      return null;
    } catch (e) {
      print('❌ 방 업데이트 오류 (roomId: $roomId): $e');
      return null;
    }
  }

  // 일반 클럽 리스트 가져오기 (정렬된)
  List<MapEntry<int, Map<dynamic, dynamic>>> getRoomsList(BuildContext context) {
    return _getSortedRoomsList(context, _rooms);
  }

  // 번개챗 리스트 가져오기 (정렬된)
  List<MapEntry<int, Map<dynamic, dynamic>>> getQuickList(BuildContext context) {
    return _getSortedRoomsList(context, _quickRooms);
  }

  // 방 리스트 정렬 (최신 채팅 시간 기준)
  List<MapEntry<int, Map<dynamic, dynamic>>> _getSortedRoomsList(
      BuildContext context,
      Map<int, Map>? roomsMap,
      ) {
    if (roomsMap == null || roomsMap.isEmpty) {
      return <MapEntry<int, Map<dynamic, dynamic>>>[];
    }

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final List<MapEntry<int, Map<dynamic, dynamic>>> list = roomsMap.entries.toList();

      list.sort((a, b) {
        try {
          final roomAId = a.key;
          final roomBId = b.key;

          // 최신 채팅 시간 가져오기
          DateTime timeA = DateTime.fromMillisecondsSinceEpoch(0);
          DateTime timeB = DateTime.fromMillisecondsSinceEpoch(0);

          try {
            final latestChatA = chatProvider.latestChatTime(roomAId);
            if (latestChatA?.createAt != null) {
              timeA = latestChatA!.createAt;
            }
          } catch (e) {
            // 개별 방 오류는 무시하고 계속 진행
          }

          try {
            final latestChatB = chatProvider.latestChatTime(roomBId);
            if (latestChatB?.createAt != null) {
              timeB = latestChatB!.createAt;
            }
          } catch (e) {
            // 개별 방 오류는 무시하고 계속 진행
          }

          return timeB.compareTo(timeA); // 최신 순으로 정렬
        } catch (e) {
          print('❌ 방 정렬 비교 오류: $e');
          return 0;
        }
      });

      return list;
    } catch (e) {
      print('❌ 방 목록 정렬 오류: $e');
      return roomsMap.entries.toList();
    }
  }

  // 방 존재 여부 확인
  bool containsRoom(int roomId) {
    return (_rooms?.containsKey(roomId) ?? false) ||
        (_quickRooms?.containsKey(roomId) ?? false);
  }

  // 방이 번개챗인지 확인
  bool isQuickRoom(int roomId) {
    return _quickRooms?.containsKey(roomId) ?? false;
  }

  // 특정 방 데이터 가져오기
  Map? getRoomData(int roomId) {
    return _rooms?[roomId] ?? _quickRooms?[roomId];
  }

  // 전체 방 개수
  int get totalRoomCount {
    return (_rooms?.length ?? 0) + (_quickRooms?.length ?? 0);
  }

  // 방 제거 (채팅에서 나갔을 때)
  void removeRoom(int roomId) {
    try {
      bool removed = false;

      if (_rooms?.remove(roomId) != null) {
        removed = true;
        print('🗑️ 일반 클럽에서 제거: $roomId');
      }

      if (_quickRooms?.remove(roomId) != null) {
        removed = true;
        print('🗑️ 번개챗에서 제거: $roomId');
      }

      if (removed) {
        notifyListeners();
      }
    } catch (e) {
      print('❌ 방 제거 오류: $e');
    }
  }

  // 디버깅용 정보 출력
  void printDebugInfo() {
    print('📊 방 목록 상태:');
    print('- 일반 클럽: ${_rooms?.length ?? 0}개');
    print('- 번개챗: ${_quickRooms?.length ?? 0}개');
    print('- 전체: $totalRoomCount개');

    if (_rooms != null) {
      print('- 일반 클럽 ID: ${_rooms!.keys.toList()}');
    }

    if (_quickRooms != null) {
      print('- 번개챗 ID: ${_quickRooms!.keys.toList()}');
    }
  }
}