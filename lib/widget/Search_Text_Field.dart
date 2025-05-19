
import '../manager/project/Import_Manager.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final Function(String)? onSubmit;
  final String hintText;
  final FocusNode? node;

  const SearchTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = '검색어를 입력하세요', this.onSubmit, this.node
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmit,
      focusNode: node,
      decoration: InputDecoration(
        constraints: BoxConstraints(
          maxHeight: 48.h
        ),
        filled: true,
        fillColor: Theme.of(context).highlightColor,
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium
    );
  }
}
