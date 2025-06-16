import 'package:my_sports_calendar/widget/Nadal_Selectable_Box.dart';

import '../../../manager/project/Import_Manager.dart';

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Flexible(
                child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => provider.setGender('M'),
                    child: NadalSelectableBox(
                        selected: provider.selectedGender == 'M',
                        text: '남자'
                    )
                )
            ),
            SizedBox(width: 8.w),
            Flexible(
                child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => provider.setGender('F'),
                    child: NadalSelectableBox(
                        selected: provider.selectedGender == 'F',
                        text: '여자'
                    )
                )
            ),
          ],
        );
      },
    );
  }
}