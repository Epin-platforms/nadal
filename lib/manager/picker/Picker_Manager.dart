import 'package:my_sports_calendar/manager/picker/Bank_Picker.dart';
import 'package:my_sports_calendar/manager/picker/City_Picker.dart';
import 'package:my_sports_calendar/manager/picker/DateTime_Picker.dart';
import 'package:my_sports_calendar/manager/picker/Local_Picker.dart';

import '../project/Import_Manager.dart';

class PickerManager{

  static Future localPicker(String local) async{
    final context = AppRoute.navigatorKey.currentContext;

    if(context == null){
      return;
    }

    final res = await showDialog(
        useSafeArea: false,
        barrierColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        context: context,
        builder: (context)=> Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: LocalPicker(initLocal: local),
    ));

    return res;
  }

  static Future cityPicker(String city, String local) async{
    final context = AppRoute.navigatorKey.currentContext;

    if(context == null){
      return;
    }

    final res = await showDialog(
        useSafeArea: false,
        barrierColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        context: context,
        builder: (context)=> Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: CityPicker(local: local, initCity: city,),
        ));

    return res;
  }


  static Future dateTimePicker(DateTime initDate, {bool visibleTime = true}) async{
    final context = AppRoute.navigatorKey.currentContext;

    if(context == null){
      return;
    }

    final res = await showDialog(context: context, builder: (context)=> DateTimePicker(date: initDate, visibleTime : visibleTime));

    return res;
  }


  static Future bankPicker() async{
    final context = AppRoute.navigatorKey.currentContext;

    if(context == null){
      return;
    }

    final res = await showModalBottomSheet(
        context: context,
        builder: (context)=> BankPicker(),
        showDragHandle: true,
    );

    return res;
  }
}