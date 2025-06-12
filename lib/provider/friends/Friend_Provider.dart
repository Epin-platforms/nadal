
import '../../manager/permission/Permission_Manager.dart';
import '../../manager/project/Import_Manager.dart';
import '../../manager/server/Server_Manager.dart';

class FriendsProvider extends ChangeNotifier{
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> get friends => _friends;

  List<String> _selectedUid = [];
  List<String> get selectedUid => _selectedUid;

  setSelectedUid({required String value}){
    if(_selectedUid.contains(value)){
      _selectedUid.remove(value);
    }else{
      _selectedUid.add(value);
    }
    notifyListeners();
  }

  clearSelected(){
    _selectedUid.clear();
  }

  int _offset = 0;
  bool _hasMore = true;
  bool _fetching = false;

  getFriends() async{
    if(_fetching || !_hasMore) return;
    _fetching = true;
    notifyListeners();

    try{
      final response = await serverManager.get('user/friends?offset=$_offset');

      if(response.statusCode == 200){
        final List<Map<String, dynamic>> data = List.from(response.data);

        if(data.length < 30){
          _hasMore = false;
        }else{
          _offset++;
        }

        _friends.addAll(data);
        _friends.sort((a, b) => TextFormManager.compareKorean(a['nickName'], b['nickName'])); //가나다 순 정렬
        notifyListeners();
      }
    }catch(error){
      debugPrint(error.toString());
    }finally{
      _fetching = false;
      notifyListeners();
    }
  }


  //친구 검색
  bool _contactLoading = false;
  bool get contactLoading => _contactLoading;

  List<Map<String, dynamic>> _myContactList = [];
  List<Map<String, dynamic>> get myContactList => _myContactList;

  int _contactOffset = 0;
  bool _contactHasMore = true;

  Future<void> fetchContacts({bool reset = false}) async {
    final permission = await Permission.contacts.request();

    if (permission.isGranted) {
      if(!_contactHasMore || _contactLoading) return;
      if(reset){ //리셋이 참이라면
        _contactHasMore = true;
        _contactOffset = 0;
        _myContactList.clear();
      }
      _contactLoading = true;
      notifyListeners();
      try {
        final contacts = await FlutterContacts.getContacts(withProperties: true);

        final phoneNumbers = contacts
            .expand((c) => c.phones)
            .map((p) => normalizePhone(p.number))
            .toSet()
            .toList();

        final res = await serverManager.post('/user/friends/find-by-phone', data: {
          'phones': phoneNumbers,
          'offset': _contactOffset,
        });

        if (res.statusCode == 200) {
          final List<Map<String, dynamic>> data = List.from(res.data);

          if(data.length < 20){
            _contactHasMore = false;
          }else{
            _contactOffset++;
          }

          _myContactList.addAll(data);
        }
      } catch (error) {
        print(error);
      } finally {
        _contactLoading = false;
        notifyListeners();
      }
    } else {
      final contact = await PermissionManager.ensurePermission(
          Permission.contacts, AppRoute.context!);
      if(contact){
        fetchContacts();
      }
    }
  }


  String normalizePhone(String rawPhone) {
    // 1. 숫자만 남기기
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. 국가번호 제거: +82 → 0으로 변환
    if (digits.startsWith('82')) {
      digits = digits.replaceFirst(RegExp(r'^82'), '0');
    }

    // 3. 앞에 0 없으면 추가 (안정성 보장)
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    return digits;
  }

  //사용자 검색
  bool _searchLoading = false;
  bool get searchLoading => _searchLoading;

  searchUser(String value, BuildContext context) async{
    if(!value.startsWith('010')){ //전화번호
      if(!value.contains('@')){
        return 'form_error';
      }
    }
    if(_searchLoading) return;

    _searchLoading = true;
    notifyListeners();
    try{
      final router = GoRouter.of(context);
      final res = await serverManager.get('user/search?query=$value');

      if(res.statusCode == 200){
        final data = res.data;
        if(data?['uid'] != null){
          router.push('/user/${data!['uid']}');
        }
      }else{
        DialogManager.showBasicDialog(
            title: '사용자를 찾을 수 없어요',
            content: '입력하신 정보를 다시 확인해 주세요.',
            confirmText: '확인'
        );
      }
    }catch(error){
      print(error);
    }finally{
      _searchLoading = false;
      notifyListeners();
    }
  }

  //단일 정보 넣기
  void addUser(int fid) async{
    final res = await serverManager.get('user/add/friend?fid=$fid');

    if(res.statusCode == 200){
      final data = res.data;
      _friends.add(data);
    }
  }

  //정보 삭제
  void removeUser(String uid){
    _friends.removeWhere((e)=> e['friendUid'] == uid);
    notifyListeners();
  }

  //
  //날 팔로우하지만 상대방이 날 팔로우 안할때
  //
  List<Map<String, dynamic>>? _followerList;
  List<Map<String, dynamic>>? get followerList => _followerList;

  bool _hasMoreFollower = true;
  int? _lastFid;

  bool _followerLoading = false;
  bool get followerLoading => _followerLoading;

  Future<void> fetchFollower() async{
    if(_followerLoading || !_hasMoreFollower) return;
    _followerLoading = true;
    try{
      final id = _lastFid ?? 0;
      final res = await serverManager.get('user/follower-list?lastFid=$id');
      _followerList ??= []; // 이렇게 수정 (할당 연산자 사용)
      if(res.statusCode == 200){
        final list = List<Map<String, dynamic>>.from(res.data);
        if(list.length < 15){
          _hasMoreFollower = false;
        }
        if(list.isNotEmpty){
          _lastFid = list.lastOrNull?['fid'];
        }
        _followerList!.addAll(list);
      }
      notifyListeners();
    }catch(error){
      _followerList = [];
      print('날 팔로우한 친구 불러오기 오류 $error');
    }finally{
      _followerLoading = false;
      notifyListeners();
    }
  }
}