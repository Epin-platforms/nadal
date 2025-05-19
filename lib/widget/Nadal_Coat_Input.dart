import '../manager/project/Import_Manager.dart';

class NadalCoatInput extends StatefulWidget {
  const NadalCoatInput({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<NadalCoatInput> createState() => _NadalCoatInputState();
}

class _NadalCoatInputState extends State<NadalCoatInput> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      autofocus: true,
      controller: widget.controller,
      style: theme.textTheme.labelLarge,
      decoration: InputDecoration(
        counterText: '',
        counter: Container(),
        constraints: BoxConstraints(maxHeight: 24.h, maxWidth: 120.w),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none
      ),
    );
  }
}
