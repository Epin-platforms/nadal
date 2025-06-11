import '../project/Import_Manager.dart';

class LocalPicker extends StatefulWidget {
  const LocalPicker({super.key, this.initLocal});
  final String? initLocal;

  @override
  State<LocalPicker> createState() => _LocalPickerState();
}

class _LocalPickerState extends State<LocalPicker> {
  final List<String> _locals = ListPackage.local.keys.toList();
  late String _selectedLocal;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    _selectedLocal = widget.initLocal ?? _locals.first;

    final initialIndex = _locals.indexOf(_selectedLocal);
    _wheelController = FixedExtentScrollController(
        initialItem: initialIndex.clamp(0, _locals.length - 1)
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    if (index < 0 || index >= _locals.length) return;

    final selectedItem = _locals[index];
    if (selectedItem == _selectedLocal) {
      Navigator.of(context).pop(selectedItem);
    } else {
      _selectedLocal = selectedItem;
      _wheelController.animateToItem(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScrollChanged(int index) {
    if (index >= 0 && index < _locals.length) {
      _selectedLocal = _locals[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '지역선택',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedLocal),
              child: Text(
                '확인',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                // 제목
                Text(
                  '지역을 선택해주세요',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              
                SizedBox(height: 60.h),
              
                // 휠 스크롤뷰
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _wheelController,
                    itemExtent: 50.h,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: _onScrollChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final isSelected = _selectedLocal == _locals[index];
              
                        return GestureDetector(
                          onTap: () => _selectItem(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: isSelected
                                  ? colorScheme.primary.withAlpha(30)
                                  : Colors.transparent,
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            child: Text(
                              _locals[index],
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withAlpha(180),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _locals.length,
                    ),
                  ),
                ),
              
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}