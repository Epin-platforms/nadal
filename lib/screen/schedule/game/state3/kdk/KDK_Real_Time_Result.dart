import '../../../../../manager/project/Import_Manager.dart';

class KdkRealTimeResult extends StatelessWidget {
  const KdkRealTimeResult({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            title: '실시간 현황',
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [

              ],
            ),
          ),
        )
    );
  }
}
