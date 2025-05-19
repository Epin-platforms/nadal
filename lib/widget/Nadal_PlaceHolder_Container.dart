import '../manager/project/Import_Manager.dart';

class NadalPlaceholderContainer extends StatelessWidget {
  const NadalPlaceholderContainer({super.key, this.height = 20, this.width = 120, this.alignment = Alignment.centerLeft});
  final double height;
  final double width;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).highlightColor,
          borderRadius: BorderRadius.circular(8)
        ),
      ),
    );
  }
}
