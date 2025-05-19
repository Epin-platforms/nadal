import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/manager/picker/Number_Picker.dart';

import '../../../manager/project/Import_Manager.dart';

class CareerField extends StatelessWidget {
  const CareerField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Text('이제 마지막이에요,\n테니스를 시작한 지 얼마나 되셨나요?', style: Theme.of(context).textTheme.titleLarge,),
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  height: 60,
                  child: NumberPicker(onSelect: (int value){
                    registerProvider.setCareerDate(value);
                  }),
                ),
                Positioned(
                  right: 0, top: 0, bottom: 0,
                  child: IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(CupertinoIcons.chevron_up, size: 18, color: Theme.of(context).highlightColor,),
                        Icon(CupertinoIcons.chevron_down, size: 18, color: Theme.of(context).highlightColor,),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
