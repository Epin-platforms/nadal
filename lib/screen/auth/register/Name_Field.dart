import '../../../manager/project/Import_Manager.dart';

class NameField extends StatelessWidget {
  const NameField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterProvider>(
      builder: (context, provider, child) {
        return NadalTextField(
          controller: provider.nameController,
          label: '이름',
          maxLength: 10,
        );
      },
    );
  }
}
