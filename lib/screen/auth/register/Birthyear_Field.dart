import '../../../manager/project/Import_Manager.dart';

class BirthYearField extends StatelessWidget {
  const BirthYearField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return NadalTextField(
          controller: provider.birthYearController,
          maxLength: 4,
          label: '출생연도',
          keyboardType: TextInputType.number,
        );
      },
    );
  }
}
