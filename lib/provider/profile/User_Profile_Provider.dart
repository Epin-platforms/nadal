import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/dialog/Dialog_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';

class UserProfileProvider extends ChangeNotifier{
  late String _uid;
  String get uid => _uid;

  UserProfileProvider(String? uid){
    if(uid == null){
      _user = {};
      AppRoute.context?.pop();
      DialogManager.showBasicDialog(title: '알수없는 사용자 입니다', content: '이미 탈퇴한 사용자입니다', confirmText: '확인');
    }else{
      _uid = uid;
      setIsFollow(uid);
      fetchUser(uid);
    }
  }

  Map? _user;
  Map? get user => _user;

  fetchUser(String uid) async{
    try{
      final res = await serverManager.get('/user/profile/$uid');

      if(res.statusCode == 200){
        final data = res.data;
        _user = data;
      }else{
        _user = {};
      }

    }catch(e){
      print(e);
      AppRoute.context?.pop();
      DialogManager.showBasicDialog(title: '알수없는 사용자 입니다', content: '이미 탈퇴한 사용자입니다', confirmText: '확인');
    }finally{
      notifyListeners();
    }
  }

  List<Map>? _games;
  List<Map>? get games => _games;

  int _offset = 0;
  bool _hasMore = true;
  bool _loading = false;

  fetchGames() async{
    if(!_hasMore || _loading) return;
    try{
      _loading = true;
      notifyListeners();
      final res = await serverManager.get('user/profile-game?uid=$uid&offset=$_offset');

      _games ??= [];

      if(res.statusCode == 200){
        final list = List.from(res.data);

        if(list.length < 15){
          _hasMore = true;
        }else{
          _offset++;
        }

        for(var game in list){
          _games!.add(game);
        }
      }
    }catch(error){
      _games = [];
    }finally{
      _loading = false;
      notifyListeners();
    }
  }


  //친구 추가했는지 판단
  bool? _isFollow;
  bool? get isFollow => _isFollow;

  setIsFollow(String uid) async{
    final res = await serverManager.get('user/friend/$uid');

    if(res.statusCode == 200){
      _isFollow = res.data;
      notifyListeners();
    }
  }

  bool _followLoading = false;
  bool get followLoading => _followLoading;

  Future<void> onChangedFollow(BuildContext context) async{
    if(_isFollow == null) return;
    if(_followLoading) return;
    try{
      final friendProvider = context.read<FriendsProvider>();
      if(_isFollow!){ //팔로우 중이라면 친구삭제
        final res = await serverManager.delete('user/friend/$_uid');

        if(res.statusCode == 200){
          _isFollow = false;
          friendProvider.removeUser(_uid);
          user!['follower']--;
        }
      }else{

        final res = await serverManager.post('user/friend/$_uid');
        if(res.statusCode == 201){//팔로우 중인 상태라면
          final data = res.data;
          print(data);
          friendProvider.addUser(data['fid']);
          _isFollow = true;
          user!['follower']++;
        }
      }
    }catch(error){
      print(error);
      DialogManager.showBasicDialog(title: '팔로우 상태 변경에 실패했습니다', content: '잠시후 다시 시도해주세요', confirmText: '확인');
    }finally{
      _followLoading = false;
      notifyListeners();
    }
  }

}