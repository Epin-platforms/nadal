import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class RoomPreviewProvider extends ChangeNotifier{
  Map? _room;
  Map? get room => _room;

  RoomPreviewProvider(dynamic roomId){
    final id = roomId is int ? roomId : int.parse(roomId);
    _fetchPreviewRoom(id);
  }

  Future<void> _fetchPreviewRoom(int roomId) async{
    final res = await serverManager.get('room/preview/$roomId');

    if(res.statusCode == 200){
      _room = res.data;
      if(_room!['isJoined'] == 1){ //이미 참가중이라면
        AppRoute.context!.pushReplacement('/room/${room!['roomId']}');
      }
      notifyListeners();
    }else{
      AppRoute.context?.pop();
    }
  }

  Future<void> registerStart(String enterCode) async{
    AppRoute.pushLoading();
    //첫 신청은 패스워드 없이
    if(room!['useNickname'] == 0 && AppRoute.context?.read<UserProvider>().user?['verificationCode'] == null){
        AppRoute.popLoading();
        DialogManager.showBasicDialog(title: '앗! 이런', content: "해당 방은 본명기반 운영을 하고있어요!\n프로필 내에 카카오 인증 후 시도해주세요", confirmText: "알겠어요");
        return;
    }

    final res = await serverManager.post('room/register/${room!['roomId']}', data: {'enterCode' : enterCode});
    AppRoute.popLoading();

    if(res.statusCode == 204){
      //입장코드 필요
      DialogManager.showInputDialog(context: AppRoute.context!, title: "입장코드가 있어요", content: '해당 방에 입장하기위해 입장코드를\n입력해주세요', confirmText: "입장하기", onConfirm: (String value) async{
        registerStart(value);
      }, cancelText: '취소');
      return;
    }else if(res.statusCode == 202){
      DialogManager.showBasicDialog(title: "앗! 이런", content: "참가를 위한 비밀번호가 일치하지 않아요", confirmText: "확인");
      return;
    }else if(res.statusCode == 201){ //이미 가입된 유저
      AppRoute.context!.pushReplacement('/room/${room!['roomId']}');
      return;
    }else if(res.statusCode == 200){ //새로 가입하는 유저
      AppRoute.context!.pushReplacement('/room/${room!['roomId']}');
      return;
    }
  }
}