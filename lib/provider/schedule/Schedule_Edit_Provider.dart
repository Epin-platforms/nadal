import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
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
    _startDate = DateTime.parse(_schedule['startDate']);
    _endDate = DateTime.parse(_schedule['endDate']);
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

  Future<void> _fetchAccount(int accountId) async{
    try {
      final res = await serverManager.get('user/account/only/$accountId');

      if(res.statusCode == 200 && res.data != null){
        _account = res.data;
        notifyListeners();
      }
    } catch (e) {
      print('계좌 정보 가져오기 실패: $e');
    }
  }

  void setTag(int index){
    if(_tag != tags[index]){
      if(_tag == '게임' && tags[index] != "게임"){
        _isKDK = null;
        _isSingle = null;
      }

      _tag = tags[index];

      if(_tag == "게임"){
        _useParticipation = true;
      }
      notifyListeners();
    }
  }

  void setStartDate(DateTime res){
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

  void setEndDate(DateTime res){
    if(res != endDate){
      _endDate = res;
      notifyListeners();
    }
  }

  void setAllDay(bool value){
    _isAllDay = value;
    if(_isAllDay){ //하루종일이 켜지면
      _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 6, 0);
      _endDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 23, 00);
    }
    notifyListeners();
  }

  void setAddress(String? value, String? sido){
    if(_address != value){
      _address = value;
      _addressPrefix = sido;
      notifyListeners();
    }
  }

  void setUseParticipation(bool value){
    _useParticipation = value;
    notifyListeners();
  }

  void setUseGenderLimit(bool value){
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

  void setMaleGenderLimit(int cnt){
    _maleLimit = cnt;
    notifyListeners();
  }

  void setFemaleGenderLimit(int cnt){
    _femaleLimit = cnt;
    notifyListeners();
  }

  void setUseAccount(bool value){
    _useAccount = value;
    notifyListeners();
  }

  void setAccount(dynamic map){
    _account = map;
    notifyListeners();
  }

  ///게임에 필요한 내용
  bool? _isKDK;
  bool? _isSingle;

  bool? get isKDK => _isKDK;
  bool? get isSingle => _isSingle;

  void setIsKDK(bool val){
    if(val != _isKDK){
      _isKDK = val;
      notifyListeners();
    }
  }

  void setIsSingle(bool val){
    if(val != _isSingle){
      _isSingle = val;
      notifyListeners();
    }
  }

  Future<void> updateSchedule() async {
    // 🔧 수정: 제목 검증
    final title = _titleController.text.trim();
    if (title.isEmpty || title.length > 30) {
      DialogManager.errorHandler('흠.. 제목이 이상해요 🤔');
      return;
    }

    // 🔧 수정: 시간 검증 로직 수정
    if (!_isAllDay && _endDate.isBefore(_startDate)) {
      DialogManager.errorHandler('흠.. 종료 시간이 시작 시간보다 빨라요 🤔');
      return;
    }

    // 🔧 수정: 하루종일 일정의 경우 시작과 종료가 같은 날인지 확인
    if (_isAllDay) {
      final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
      if (!startDay.isAtSameMomentAs(endDay)) {
        DialogManager.errorHandler('흠.. 하루종일 일정은 같은 날이어야 해요 🤔');
        return;
      }
    }

    if (_useAccount && _account == null) {
      DialogManager.errorHandler('흠.. 선택된 계좌가 없어요 🤔');
      return;
    }

    if (_tag == "양도" && _address == null) {
      DialogManager.errorHandler('흠.. 양도를 위한 장소가 없어요 🤔');
      return;
    }

    // 🔧 개선: 주소가 없으면 상세주소도 초기화
    if (_address == null && _addressDetailController.text.isNotEmpty) {
      _addressDetailController.clear();
    }

    if (_tag == "게임") {
      if (_isKDK == null || _isSingle == null) {
        DialogManager.errorHandler('흠.. 게임을 위한 진행 옵션이 없어요 🤔');
        return;
      }

      if (useGenderLimit && _maleLimit != null && _femaleLimit != null) {
        final total = _maleLimit! + _femaleLimit!;
        if (_isKDK! && _isSingle!) { //대진표 단식
          if (total < GameManager.min_kdk_single_member || total > GameManager.max_kdk_single_member) {
            DialogManager.errorHandler('대진표 단식은 ${GameManager.min_kdk_single_member}~${GameManager.max_kdk_single_member}인까지 가능해요');
            return;
          }
        } else if (_isKDK! && !_isSingle!) { //대진표 복식
          if (total < GameManager.min_kdk_double_member || total > GameManager.max_kdk_double_member) {
            DialogManager.errorHandler('대진표 복식은 ${GameManager.min_kdk_double_member}~${GameManager.max_kdk_double_member}인까지 가능해요');
            return;
          }
        } else if (!_isKDK! && _isSingle!) { //토너먼트 단식
          if (total < GameManager.min_tour_single_member || total > GameManager.max_tour_single_member) {
            DialogManager.errorHandler('토너먼트 단식은 ${GameManager.min_tour_single_member}~${GameManager.max_tour_single_member}인까지 가능해요');
            return;
          }
        }
      }
    }

    await _startUpdate();
  }

  Future<void> _startUpdate() async{
    AppRoute.pushLoading();

    try{
      final updateData = _toMap();

      // 🔧 개선: 변경사항이 없으면 업데이트하지 않음
      if (updateData.length <= 1) { // scheduleId만 있는 경우
        AppRoute.popLoading();
        DialogManager.showBasicDialog(
            title: '변경사항이 없어요',
            content: '수정할 내용이 없습니다',
            confirmText: '확인'
        );
        return;
      }

      final res = await serverManager.put('schedule/update', data: updateData);
      AppRoute.popLoading();
      if(res.statusCode == 200){
        final context = AppRoute.context;
        if (context?.mounted == true) {
          context!.read<UserProvider>().fetchMySchedules(startDate, force: true);
          context.pop(true);
        }
      } else {
        _handleUpdateError('서버 응답 오류: ${res.statusCode}');
      }
    } catch(error) {
      AppRoute.popLoading();
      print('일정 수정 오류: $error');
      _handleUpdateError('네트워크 오류가 발생했습니다');
    }
  }

  void _handleUpdateError(String message) {
    DialogManager.showBasicDialog(
        title: '수정에 실패했어요',
        content: '잠시후 다시 시도해주세요\n($message)',
        confirmText: '확인'
    );
  }

  Map<String, dynamic> _toMap() {
    final Map<String, dynamic> map = {
      'scheduleId' : _schedule['scheduleId']
    };

    void checkAndAdd(String key, dynamic currentValue) {
      final originalValue = _schedule[key];

      // 🔧 개선: 더 정확한 비교
      if (_isDifferent(originalValue, currentValue)) {
        map[key] = currentValue;
      }
    }

    checkAndAdd('tag', _tag);
    checkAndAdd('isAllDay', _isAllDay);
    checkAndAdd('startDate', _startDate.toIso8601String());
    checkAndAdd('endDate', _endDate.toIso8601String());
    checkAndAdd('title', _titleController.text.trim());
    checkAndAdd('description', _descriptionController.text.trim());
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
      checkAndAdd('isSingle', _isSingle);
      checkAndAdd('isKDK', _isKDK);
    }

    return map;
  }

  // 🔧 새로운 메서드: 값 비교
  bool _isDifferent(dynamic original, dynamic current) {
    // null 처리
    if (original == null && current == null) return false;
    if (original == null || current == null) return true;

    // 타입별 비교
    if (original is bool && current is int) {
      return (original ? 1 : 0) != current;
    }
    if (original is int && current is bool) {
      return original != (current ? 1 : 0);
    }

    // 문자열의 경우 trim 처리
    if (original is String && current is String) {
      return original.trim() != current.trim();
    }

    return original != current;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }
}