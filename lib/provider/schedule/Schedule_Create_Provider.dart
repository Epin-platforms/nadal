import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class ScheduleCreateProvider extends ChangeNotifier{
  final List<String> tags = ['게임', '모임', '공지', '양도', '기타'];

  late bool _canUseGenderLimit;
  bool get canUseGenderLimit => _canUseGenderLimit;

  late int? _roomId;
  int? get roomId => _roomId;

  ScheduleCreateProvider(ScheduleParams item){
    _roomId = item.roomId;
    _canUseGenderLimit = item.canUseGenderLimit ?? false;

    final date = item.date;

    if(date != null){
      final now = DateTime.now();
      _startDate = DateTime(date.year, date.month, date.day, now.hour + 1);
      _endDate = startDate.add(const Duration(hours: 1));
    }else{
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day, now.hour + 1);
      _endDate = startDate.add(const Duration(hours: 1));
    }

    _tag = tags[0];
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressDetailController = TextEditingController();
  }

  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get addressDetailController =>  _addressDetailController;

  String? get address => _address;
  String get tag => _tag;
  bool get useAccount => _useAccount;
  bool get isAllDay => _isAllDay;
  bool get useParticipation => _useParticipation;
  bool get useGenderLimit => _useGenderLimit;

  int? get maleLimit => _maleLimit;
  int? get femaleLimit => _femaleLimit;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressDetailController;

  int? _maleLimit;
  int? _femaleLimit;

  String? _address;
  String? _addressPrefix;

  String _tag = '';
  bool _useAccount = false;
  bool _isAllDay = false;
  bool _useParticipation = true;
  bool _useGenderLimit = false;


  late DateTime _startDate;
  late DateTime _endDate;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  Map? _account;
  Map? get account => _account;

  void setTag(int index){
    if(index == -1){
        _tag = '개인';
        _isKDK = null;;
        _isSingle = null;
        _useParticipation = false;
        notifyListeners();
    }else if(_tag != tags[index]){
      if(_tag == '게임' && tags[index] != "게임"){
        _isKDK = null;;
        _isSingle = null;
      }

      _tag = tags[index];

      if(_tag == "게임"){
        _useParticipation = true;
      }else if(tags[index] == '공지' || tags[index] == '양도'){
        if(_useParticipation){
          _useParticipation = false;
        }
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
        if(_endDate.isBefore(_startDate) || _endDate.difference(_startDate).inMinutes == 0){ //차이가 없을경우
          _endDate = res.add(const Duration(hours: 1));
        }
      }
      notifyListeners();
    }
  }

  void setEndDate(DateTime res){
    if(res != endDate){
      _endDate = res;
      if(_endDate.isBefore(_startDate) || _endDate.difference(_startDate).inMinutes == 0){
        _startDate = res.subtract(const Duration(hours: 1));
      }
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

      if(_isKDK == false && _isSingle == false){
        setUseGenderLimit(false);
      }
      notifyListeners();
    }
  }

  void setIsSingle(bool val){
    if(val != _isSingle){
      _isSingle = val;
      if(_isKDK == false && _isSingle == false){
        setUseGenderLimit(false);
      }
      notifyListeners();
    }
  }

  Future create() async{
    if(_titleController.text.isEmpty || _titleController.text.length > 30){
        DialogManager.errorHandler('흠.. 제목이 이상해요 🤔');
        return;
    }

    if(!_isAllDay && _endDate.isBefore(_startDate)){
      DialogManager.errorHandler('흠.. 일정 시간이 이상해요 🤔');
      return;
    }

    if(_useAccount && _account == null){
      DialogManager.errorHandler('흠.. 선택된 계좌가 없어요 🤔');
      return;
    }

    if(_tag == "양도" && _address == null){
      DialogManager.errorHandler('흠.. 양도를 위한 장소가 없어요 🤔');
      return;
    }

    if(_address == null && _addressDetailController.text.isNotEmpty){
      _addressDetailController.clear();
    }

    if(_tag == "공지" && _descriptionController.text.replaceAll(' ', '').replaceAll('\n', '').isEmpty){
      DialogManager.errorHandler('공지는 메모 내용이 공개돼요🤔\n메모를 작성해주세요');
      return;
    }

    if(_tag == "게임"){
        if(_isKDK == null || _isSingle == null){
          DialogManager.errorHandler('흠.. 게임을 위한 진행 옵션이 없어요 🤔');
          return;
        }

        if(useGenderLimit){
          final total = maleLimit! + femaleLimit!;
          if(_isKDK! && _isSingle!){ //대진표 단식
            if(total < GameManager.min_kdk_single_member || total > GameManager.max_kdk_double_member){
              DialogManager.errorHandler('대진표 단식은 ${GameManager.min_kdk_single_member}~${GameManager.max_kdk_double_member}인까지 가능해요');
              return;
            }
          }else if(_isKDK! && !_isSingle!){
            if(total < GameManager.min_kdk_double_member || total > GameManager.max_kdk_double_member){
              DialogManager.errorHandler('대진표 단식은 ${GameManager.min_kdk_double_member}~${GameManager.max_kdk_double_member}인까지 가능해요');
              return;
            }
          }else if(!_isKDK! && _isSingle!){
            if(total < GameManager.min_tour_single_member || total > GameManager.max_tour_single_member){
              DialogManager.errorHandler('토너먼트 단식은 ${GameManager.min_tour_single_member}_${GameManager.max_tour_single_member} 가능해요');
              return;
            }
          }
        }
    }
    return await startCreate();
  }

  Future<int> startCreate() async{
    AppRoute.pushLoading();
    int scheduleId = 404;

    try{
      final res = await serverManager.post('schedule/create', data: _toMap());

      if(res.statusCode == 200){
        scheduleId = res.data['scheduleId'];
        AppRoute.context?.read<UserProvider>().fetchMySchedules(startDate, force: true);
      }
    }finally{
      AppRoute.popLoading();
    }

    return scheduleId;
  }


  Map _toMap(){
    return {
      'tag' : _tag,
      'isAllDay' : _isAllDay,
      'startDate' : _startDate.toIso8601String(),
      'endDate' : _endDate.toIso8601String(),
      'title' : _titleController.text,
      'description' : _descriptionController.text,
      'roomId' : _roomId,
      'useAddress' : address == null ? false : true,
      'address' : _address,
      'addressPrefix' : _addressPrefix,
      'addressDetail' : _addressDetailController.text.trim().isEmpty ? null : _addressDetailController.text,
      'useAccount' : _useAccount,
      'accountId' : _account?['accountId'],
      'useParticipation' : _useParticipation,
      'useGenderLimit' : _useGenderLimit,
      'maleLimit' : _maleLimit,
      'femaleLimit' : _femaleLimit,
      'sports' : tag == "게임" ? '테니스' : null,
      "state" : tag == "게임" ? 0 : null,
      "finalScore" : tag == "게임" ? 6 : null,
      "isSingle" : _isSingle,
      "isKDK" : _isKDK
    };
  }
}