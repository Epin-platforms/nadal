import '../../../manager/project/Import_Manager.dart';

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return NadalTextField(controller: registerProvider.emailController, label: '이메일');
  }
}
