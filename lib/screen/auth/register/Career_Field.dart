import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/manager/picker/Number_Picker.dart';

import '../../../manager/project/Import_Manager.dart';

class CareerField extends StatelessWidget {
  const CareerField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          Text('이제 마지막이에요,\n테니스를 시작한 지 얼마나 되셨나요?', style: theme.textTheme.titleLarge,),
          SizedBox(width: 8.w,),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_)=> NumberPicker(
                    onSelect: (index){
                      registerProvider.setCareerDate(index);
                    }, 
                    title: '구력 설정',
                    unit: '년',
                    initialValue: registerProvider.careerDate,
                )));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.highlightColor, width: 2)
                ),
                alignment: Alignment.center,
                width: 60.w,
                child: Text('${registerProvider.careerDate} 년', style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18.sp,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500
                )),
            )
          ))
        ],
      ),
    );
  }
}
