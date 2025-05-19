import '../project/Import_Manager.dart';

class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.local, this.initCity});
  final String local;
  final String? initCity;
  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  late List<String> cities;
  late String city;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    cities = ListPackage.local[widget.local]!.toList();
    city = widget.initCity ?? cities[0];
    _wheelController = FixedExtentScrollController(initialItem: cities.indexOf(city));
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    final selected = cities[index];
    if (selected == city) {
      Navigator.of(context).pop(selected); // 선택된 항목이면 pop
    } else {
      _wheelController.animateToItem(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        city = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IosPopGesture(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(city),
                child: Text('확인', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.only(bottom: 200, top: 100),
            child: ListWheelScrollView.useDelegate(
              controller: _wheelController,
              itemExtent: 45,
              diameterRatio: 1.2,
              physics: FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  city = cities[index];
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  return GestureDetector(
                    onTap: () => _handleTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        cities[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: city == cities[index]
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))

                      ),
                    ),
                  );
                },
                childCount: cities.length,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
