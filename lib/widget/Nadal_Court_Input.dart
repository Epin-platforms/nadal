import '../manager/project/Import_Manager.dart';

class NadalCourtInput extends StatefulWidget {
  const NadalCourtInput({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<NadalCourtInput> createState() => _NadalCourtInputState();
}

class _NadalCourtInputState extends State<NadalCourtInput> {
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
