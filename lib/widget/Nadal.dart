import '../manager/project/Import_Manager.dart';

class Nadal extends StatelessWidget {
  const Nadal({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/image/app/nadal.svg', height: size, width: size,);
  }
}
