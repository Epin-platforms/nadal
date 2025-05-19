import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/auth/social/Apple_Manager.dart';
import 'package:my_sports_calendar/manager/auth/social/Google_Manager.dart';
import 'package:my_sports_calendar/manager/auth/social/Kakao_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/util/handler/Security_Handler.dart';
import '../../manager/project/Import_Manager.dart';

enum UserProviderState{
  none, loggedIn, loggedOut
}

class UserProvider extends ChangeNotifier{
  UserProviderState _state = UserProviderState.none;
  UserProviderState get state => _state;

  final _auth = FirebaseAuth.instance;

  Map? _user;
  Map? get user => _user;


  userProviderInit(){
    _firebaseUserListener();
  }

  //파이어베이스 유저 리스너
  bool _firstLoading = false;
  void _firebaseUserListener(){
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if(user == null){
        _state = UserProviderState.loggedOut;
        notifyListeners();
      }else{
        fetchUserData(loading: _firstLoading);
        _firstLoading = true;
      }
    });
  }

  Future<void> fetchUserData({bool loading = true}) async{
     if(loading){
       AppRoute.pushLoading();
     }
       final device = await SecurityHandler.getDeviceInfo();
       final response = await serverManager.post('user/login', data: device);

       if(response.statusCode == 201){ //파이어베이스에는있고 사용자 없는 상태면 가입페이지
         if(AppRoute.navigatorKey.currentContext != null){
           GoRouter.of(AppRoute.navigatorKey.currentContext!).go('/register');
         }
       }else if(response.statusCode != null && (response.statusCode! ~/ 100) == 2){
         //사용자가 존재함
         _state = UserProviderState.loggedIn;
         _user = response.data;

         //만약 banCode
         if(_user?['banType'] != null){
           final banType = _user?['banType'];
           final startBlock = DateTime.tryParse(_user?['startBlock'])?.toLocal();
           final endBlock = DateTime.tryParse(_user?['startBlock'])?.toLocal();
           final lastLogin = DateTime.tryParse(response.data['lastLogin'])?.toLocal();

           //마지막 접속일자 업데이트전 확인해서 블락 시작일이 아니라면 다이얼로그 표시
           if(lastLogin != null && startBlock != null && endBlock != null){
             final isBanActive = (lastLogin.isAfter(startBlock));
             if (isBanActive) {
               final until = '${DateFormat('MM월 dd일 hh시 mm분').format(endBlock)}까지';
               DialogManager.showBasicDialog(
                 title: '사용자 제제 알림',
                 content: '선수님께서 일정 신고 누적으로 인해 ${banType == 'schedules' ? '스케줄 생성' : banType == 'community' ? '커뮤니티 활동' : '일정 화동'}이 $until 제한됩니다',
                 confirmText: '확인',
                 icon: Icon(BootstrapIcons.ban, size: 30, color: Color(0xFF007E94)),
               );
             }
           }
         }
       }else if(response.statusCode == 409){ //디바이스 출동로인한 세션 오류
         final deviceName = response.data['deviceName'];
         await DialogManager.showBasicDialog(icon: Icon(CupertinoIcons.device_phone_portrait, size: 30,),title: '다른 기기에서 로그인 중', content: '$deviceName기기에서 로그인 중입니다.\n현재 기기로 로그인 하시겠습니까?', confirmText: '로그인',
             cancelText: '취소', onConfirm: () async{

               final response = await serverManager.put('user/deviceUpdate', data: device);

               if(response.statusCode == 200){
                 fetchUserData();
               }

          }, onCancel: (){
                if(Platform.isIOS){
                  exit(0);
                }else{
                  SystemNavigator.pop();
                }
             }
         );
     }

     if(loading){
       AppRoute.popLoading();
     }
     notifyListeners();
  }

  Future reCertification(String? social) async{
      if(social == "oidc.kakao"){
        await KakaoManager().kakaoLogin();
      }else if(social == "google.com"){
        await GoogleManager().googleLogin();
      }else if(social == "apple.com"){
        await AppleManager().appleLogin();
      }

      return true;
  }


  logout(bool removeUser) async{
      try{
        AppRoute.pushLoading();

        final provider = _auth.currentUser?.providerData;
        if(provider?.isEmpty ?? true){//잘못된 접근으로 없다면 그냥 로그아웃
          //삭제가아닌 그냥 로그아웃시 기기 세션 끄기
          final res = await serverManager.put('user/session/turnOff');

          if(res.statusCode == 200){
            await _auth.signOut();
          }
          AppRoute.navigatorKey.currentContext!.go('/login');
          return;
        }


        final social = _auth.currentUser?.providerData[0].providerId;


        if(social == null){
          throw Exception("다시 로그인하는 데 문제가 발생했어요.\n잠시 후 다시 시도해 주세요.");
        }

        //재인증 후 로그안웃 진행
        final result = await reCertification(social);

        if(!result){
          throw Exception("다시 로그인하는 데 문제가 발생했어요.\n잠시 후 다시 시도해 주세요.");
        }

        //소셜 링크 제거
        if(social == "oidc.kakao"){
          await KakaoManager().unlink();
        }else if(social == "google.com"){
          await GoogleManager().unLink();
        }

        //완료
        if(removeUser){
          try {
            await _auth.currentUser!.delete();
          } catch (e) {
            if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
              await _auth.currentUser!.delete();
            }
          }
        } else {
          //삭제가아닌 그냥 로그아웃시 기기 세션 끄기
          final res = await serverManager.put('user/session/turnOff');

          if(res.statusCode == 200){
            _auth.signOut();
          }
        }

        AppRoute.navigatorKey.currentContext!.go('/login');
      }catch(error){
        AppRoute.popLoading();
        print("로그아웃 실패: $error");
        DialogManager.errorHandler(null);
      }
  }

  updateProfile() async{
    final res = await serverManager.post('user/my', data: {'updateAt' : user!['updateAt']});

    if(res.statusCode == 200){
      _user = Map.of(res.data);
      notifyListeners();
    }
  }

  //사용자 스케줄 불러오기

  List<Map> _schedules = [];
  List<Map> get schedules => _schedules;

  List<String> _fetchCached = [];
  List<String> get fetchCached => _fetchCached;

  Future<void> fetchMySchedules(DateTime date, {bool force = false, bool reFetch = false}) async {
    if(reFetch){
      _fetchCached.clear();
      _schedules.clear();
    }

    final from = DateTime(date.year, date.month, 1).toIso8601String();
    final to = DateTime(date.year, date.month + 1, 0, 23, 59, 59).toIso8601String();

    if (force || !fetchCached.contains(from)) {
      final res = await serverManager.get('schedule/my?from=$from&to=$to');
      if (res.statusCode == 200) {
        final newSchedules = List.from(res.data);
        final existingIds = _schedules.map((e) => e['scheduleId']).toSet();
        final filtered = List<Map>.from(newSchedules.where((s) => !existingIds.contains(s['scheduleId'])));
        _schedules.addAll(filtered);
        notifyListeners();
      }
      fetchCached.add(from);
    }
  }

  void removeScheduleById(int id) {
    _schedules.removeWhere((e) => e['scheduleId'] == id);
    notifyListeners();
  }


}