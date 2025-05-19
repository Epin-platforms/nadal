import 'package:dio/dio.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class AffiliationProvider extends ChangeNotifier{
  AffiliationProvider(int? affiliationId){
    _originAffiliationId = affiliationId;
    _selectedRoomId = _originAffiliationId;
    initAffiliation();
  }

  late final int? _originAffiliationId;
  int? get originAffiliationId => _originAffiliationId;

  List<Map>? _myRooms;
  List<Map>? get myRooms => _myRooms;

  void initAffiliation() async{
    try{
      final response = await serverManager.get('room/affiliation');

      if(response.statusCode == 200){
        _myRooms = List<Map<String, dynamic>>.from(response.data);

        if(_originAffiliationId == null && _myRooms!.isNotEmpty){
          _selectedRoomId = _myRooms!.first['roomId'];
        }
      }
    }finally{
      notifyListeners();
    }
  }

  int? _selectedRoomId;
  int? get selectedRoomId => _selectedRoomId;

  void setRoomId(int value){
    if(_selectedRoomId != value){
      _selectedRoomId = value;
    }
  }

  Future<void> saveAffiliation(BuildContext context) async{
    AppRoute.pushLoading();
    try{
      final res = await serverManager.put('user/update/affiliation', data: {"roomId" : _selectedRoomId});

      if(res.statusCode == 200){
        AppRoute.popLoading();
        await context.read<UserProvider>().updateProfile();
        SnackBarManager.showCleanSnackBar(context, '대표클럽 설정이 완료되었습니다');
        context.pop();
      }
    }finally{
      AppRoute.popLoading();
    }
  }
}