
import '../project/Import_Manager.dart';

class LocalPicker extends StatefulWidget {
  const LocalPicker({super.key, this.initLocal});
  final String? initLocal;

  @override
  State<LocalPicker> createState() => _LocalPickerState();
}

class _LocalPickerState extends State<LocalPicker> {
  final locals = ListPackage.local.keys.toList();
  late String local;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    local = widget.initLocal ?? locals[0];
    _wheelController = FixedExtentScrollController(initialItem: locals.indexOf(local));
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    final selected = locals[index];
    if (selected == local) {
      Navigator.of(context).pop(selected); // 선택된 항목이면 pop
    } else {
      _wheelController.animateToItem(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        local = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                onPressed: () => Navigator.of(context).pop(local),
                child: Text('확인', style: theme.textTheme.labelLarge),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.only(bottom: 200, top: 100),
            child: ListWheelScrollView.useDelegate(
              controller: _wheelController,
              itemExtent: 45.h,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  local = locals[index];
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  return GestureDetector(
                    onTap: () => _handleTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        locals[index],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: local == locals[index]
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))
                      ),
                    ),
                  );
                },
                childCount: locals.length,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
