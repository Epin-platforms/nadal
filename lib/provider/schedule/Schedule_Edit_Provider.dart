import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class ScheduleEditProvider extends ChangeNotifier{
   final List<String> tags = ['게임', '모임', '공지', '양도', '기타'];

   late Map _schedule;
   Map get schedule => _schedule;

   late bool _existMember;

   ScheduleEditProvider(dynamic original, bool member){
     _schedule = original;
     _existMember = member;

     _address = _schedule['address'];
     _addressPrefix = _schedule['addressPrefix'];
     _tag = _schedule['tag'];
     _useAccount = _schedule['useAccount'] == 1;
     _isAllDay = _schedule['isAllDay'] == 1;
     _useParticipation = _schedule['useParticipation'] == 1;
     _useGenderLimit = _schedule['useGenderLimit'] == 1;
     _maleLimit = _schedule['maleLimit'];
     _femaleLimit = _schedule['femaleLimit'];
     _startDate = DateTime.parse(_schedule['startDate']).toLocal();
     _endDate = DateTime.parse(_schedule['endDate']).toLocal();
     if(_schedule['accountId'] != null){
       _fetchAccount(_schedule['accountId']);
     }
     _isKDK = _schedule['isKDK'] == 1;
     _isSingle = _schedule['isSingle'] == 1;

     _titleController = TextEditingController(text: _schedule['title']);
     _descriptionController = TextEditingController(text: _schedule['description']);
     _addressDetailController = TextEditingController(text: _schedule['addressDetail']);
   }

   String? get address => _address;
   String get tag => _tag;
   bool get useAccount => _useAccount;
   bool get isAllDay => _isAllDay;
   bool get useParticipation => _useParticipation;
   bool get useGenderLimit => _useGenderLimit;

   int? get maleLimit => _maleLimit;
   int? get femaleLimit => _femaleLimit;

   TextEditingController get titleController => _titleController;
   TextEditingController get descriptionController => _descriptionController;
   TextEditingController get addressDetailController =>  _addressDetailController;

   DateTime get startDate => _startDate;
   DateTime get endDate => _endDate;

   Map? get account => _account;

   late TextEditingController _titleController;
   late TextEditingController _descriptionController;
   late TextEditingController _addressDetailController;

   late bool _useAccount;
   Map? _account;

   late bool _useParticipation;

   late bool _useGenderLimit;
   int? _maleLimit;
   int? _femaleLimit;

   String? _address;
   String? _addressPrefix;

   late DateTime _startDate;
   late DateTime _endDate;
   late bool _isAllDay;

   late String _tag;


   _fetchAccount(int accountId) async{
     final res = await serverManager.get('user/account/only/$accountId');

     if(res.statusCode == 200){
       _account = res.data;
       notifyListeners();
     }
   }



   setTag(int index){
     if(_tag != tags[index]){
       if(_tag == '게임' && tags[index] != "게임"){
         _isKDK = null;;
         _isSingle = null;
       }

       _tag = tags[index];

       if(_tag == "게임"){
         _useParticipation = true;
       }
       notifyListeners();
     }
   }


   setStartDate(DateTime res){
     if(res != startDate){
       if(isAllDay){
         _startDate = DateTime(res.year, res.month, res.day, 6, 0);
         _endDate = DateTime(res.year, res.month, res.day, 23, 00);
       }else{
         _startDate = res;
       }
       notifyListeners();
     }
   }

   setEndDate(DateTime res){
     if(res != endDate){
       _endDate = res;
       notifyListeners();
     }
   }

   setAllDay(bool value){
     _isAllDay = value;
     if(_isAllDay){ //하루종일이 켜지면
       _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 6, 0);
       _endDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 23, 00);
     }
     notifyListeners();
   }

   setAddress(String? value, String? sido){
     if(_address != value){
       _address = value;
       _addressPrefix = sido;
       notifyListeners();
     }
   }

   setUseParticipation(bool value){
     _useParticipation = value;
     notifyListeners();
   }

   setUseGenderLimit(bool value){
     _useGenderLimit = value;

     if(value){
       _maleLimit = 0;
       _femaleLimit = 0;
     }else{
       _maleLimit = null;
       _femaleLimit = null;
     }
     notifyListeners();
   }

   setMaleGenderLimit(int cnt){
     _maleLimit = cnt;
     notifyListeners();
   }

   setFemaleGenderLimit(int cnt){
     _femaleLimit = cnt;
     notifyListeners();
   }

   setUseAccount(bool value){
     _useAccount = value;
     notifyListeners();
   }

   setAccount(dynamic map){
     _account = map;
     notifyListeners();
   }


   ///게임에 필요한 내용
   bool? _isKDK;
   bool? _isSingle;

   bool? get isKDK => _isKDK;
   bool? get isSingle => _isSingle;

   setIsKDK(bool val){
     if(val != _isKDK){
       if(val == false && _isSingle == false) { //토너먼트 복식으로변경
         if (_existMember) { //참가자가 있는 상태라면
           DialogManager.showBasicDialog(title: '이미 참가자가 존재합니다',
               content: '참가자가 존재할 경우, 팀 참가 게임으로의 변경은 불가합니다',
               confirmText: "확인");
           return;
         }
         _warning =true;
         setUseGenderLimit(false);
       }else if(val == true && _isSingle == false){ //토너먼트 복식에서변경
         if(_existMember){
           DialogManager.showBasicDialog(title: '이미 팀이 존재합니다',
               content: '팀이 존재할 경우, 개인 참가 개임으로의 변경은 불가합니다',
               confirmText: "확인");
         }
         _warning = true;
         return;
       }else{
         _warning = false;
       }

       _isKDK = val;
       notifyListeners();
     }
   }

   bool _warning = false;

   setIsSingle(bool val){
     if(val != _isSingle){
       if(_isKDK == false && val == false){ //단식에서 복식으로변경
         if (_existMember) { //참가자가 있는 상태라면
           DialogManager.showBasicDialog(title: '이미 참가자가 존재합니다',
               content: '참가자가 존재할 경우, 팀 참가 게임으로의 변경은 불가합니다',
               confirmText: "확인");
           return;
         }
         _warning =true;
         setUseGenderLimit(false);
       }else if(_isKDK == false && val == true){
         if (_existMember) { //참가자가 있는 상태라면
           DialogManager.showBasicDialog(title: '이미 팀이 존재합니다',
               content: '팀이 존재할 경우, 개인 참가 개임으로의 변경은 불가합니다',
               confirmText: "확인");
           return;
         }
         _warning =true;
       }else{
         _warning = false;
       }
       _isSingle = val;
       notifyListeners();
     }
   }


  Future updateSchedule() async {
    if (_titleController.text.isEmpty || _titleController.text.length > 30) {
      DialogManager.errorHandler('흠.. 제목이 이상해요 🤔');
      return;
    }

    if (!_isAllDay && _endDate.isAfter(_startDate)) {
      DialogManager.errorHandler('흠.. 일정 시간이 이상해요 🤔');
      return;
    }

    if (_useAccount && _account == null) {
      DialogManager.errorHandler('흠.. 선택된 계좌가 없어요 🤔');
      return;
    }

    if (_tag == "양도" && _address == null) {
      DialogManager.errorHandler('흠.. 양도를 위한 장소가 없어요 🤔');
      return;
    }

    if (_address == null && _addressDetailController.text.isNotEmpty) {
      _addressDetailController.clear();
    }

    if (_tag == "게임") {
      if (_isKDK == null || _isSingle == null) {
        DialogManager.errorHandler('흠.. 게임을 위한 진행 옵션이 없어요 🤔');
        return;
      }

      if (useGenderLimit) {
        final total = maleLimit! + femaleLimit!;
        if (_isKDK! && _isSingle!) { //대진표 단식
          if (total < 4 || total > 14) {
            DialogManager.errorHandler('대진표 단식은 4~14인까지 가능해요');
            return;
          }
        } else if (_isKDK! && !_isSingle!) {
          if (total < 5 || total > 16) {
            DialogManager.errorHandler('대진표 단식은 5~16인까지 가능해요');
            return;
          }
        } else if (!_isKDK! && _isSingle!) {
          if (total < 4) {
            DialogManager.errorHandler('토너먼트 단식은 4인 이상 가능해요');
            return;
          }
        }
      }
    }

    startUpdate();
  }

   Future<void> startUpdate() async{
     AppRoute.pushLoading();

     try{
       final res = await serverManager.put('schedule/update/$_warning', data: _toMap());
       AppRoute.popLoading();
       if(res.statusCode == 200){
         AppRoute.context?.read<UserProvider>().fetchMySchedules(startDate, force: true);
         AppRoute.context?.pop(true);
       }
     }catch(error){
       AppRoute.popLoading();
       DialogManager.showBasicDialog(title: '수정에 실패했어요', content: '잠시후 다시 시도해주세요', confirmText: '확인');
     }
   }


   Map<String, dynamic> _toMap() {
     final Map<String, dynamic> map = {
       'scheduleId' : _schedule['scheduleId']
     };

     void checkAndAdd(String key, dynamic currentValue) {
       if (_schedule[key] != currentValue) {
         map[key] = currentValue;
       }
     }

     checkAndAdd('tag', _tag);
     checkAndAdd('isAllDay', _isAllDay);
     checkAndAdd('startDate', _startDate.toIso8601String());
     checkAndAdd('endDate', _endDate.toIso8601String());
     checkAndAdd('title', _titleController.text);
     checkAndAdd('description', _descriptionController.text);
     checkAndAdd('useAddress', address != null);
     checkAndAdd('address', _address);
     checkAndAdd('addressPrefix', _addressPrefix);

     final trimmedAddressDetail = _addressDetailController.text.trim();
     checkAndAdd('addressDetail', trimmedAddressDetail.isEmpty ? null : trimmedAddressDetail);

     checkAndAdd('useAccount', _useAccount);
     checkAndAdd('accountId', _account?['accountId']);
     checkAndAdd('useParticipation', _useParticipation);
     checkAndAdd('useGenderLimit', _useGenderLimit);
     checkAndAdd('maleLimit', _maleLimit);
     checkAndAdd('femaleLimit', _femaleLimit);

     if (_tag == '게임') {
       checkAndAdd('sports', '테니스');
       checkAndAdd('state', 0);
       checkAndAdd('finalScore', 6);
     }

     checkAndAdd('isSingle', _isSingle);
     checkAndAdd('isKDK', _isKDK);
     return map;
   }
}