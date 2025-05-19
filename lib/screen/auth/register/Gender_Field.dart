import 'package:my_sports_calendar/widget/Nadal_Selectable_Box.dart';

import '../../../manager/project/Import_Manager.dart';

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: ()=> registerProvider.setGender('M'),
              child: NadalSelectableBox(selected: registerProvider.selectedGender == 'M', text: '남자'))
        ),
        SizedBox(width: 8,),
        Flexible(
            child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: ()=> registerProvider.setGender('F'),
                child: NadalSelectableBox(selected: registerProvider.selectedGender == 'F', text: '여자'))
        ),
      ],
    );
  }
}
