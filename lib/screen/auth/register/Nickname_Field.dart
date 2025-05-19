import '../../../manager/project/Import_Manager.dart';

class NicknameField extends StatelessWidget {
  const NicknameField({super.key, required this.registerProvider});
  final RegisterProvider registerProvider;

  @override
  Widget build(BuildContext context) {
    return NadalTextField(controller: registerProvider.nickController, label: '닉네임', maxLength: 10,);
  }
}
