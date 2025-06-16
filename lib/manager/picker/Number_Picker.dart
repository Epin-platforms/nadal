import '../project/Import_Manager.dart';

class NumberPicker extends StatefulWidget {
  const NumberPicker({
    super.key,
    this.minValue = 0,
    this.maxValue = 100,
    required this.onSelect,
    this.initialValue,
    required this.title,
    required this.unit,
  });

  final String title;
  final String unit;
  final int minValue;
  final int maxValue;
  final int? initialValue;
  final void Function(int value) onSelect;

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late int _selectedValue;
  late FixedExtentScrollController _wheelController;
  late List<int> _values;

  // 디바운서 (setState 최소화)
  Timer? _selectionDebouncer;

  @override
  void initState() {
    super.initState();

    // 값 리스트 생성 (한 번만)
    _values = List.generate(
      widget.maxValue - widget.minValue + 1,
          (index) => widget.minValue + index,
    );

    // 초기값 설정
    _selectedValue = widget.initialValue ?? widget.minValue;
    _selectedValue = _selectedValue.clamp(widget.minValue, widget.maxValue);

    // 컨트롤러 초기화
    final initialIndex = _values.indexOf(_selectedValue);
    _wheelController = FixedExtentScrollController(
      initialItem: initialIndex.clamp(0, _values.length - 1),
    );
  }

  @override
  void dispose() {
    _selectionDebouncer?.cancel();
    _wheelController.dispose();
    super.dispose();
  }

  // 직접 선택 (탭)
  void _selectItem(int index) {
    if (index < 0 || index >= _values.length) return;

    final selectedValue = _values[index];
    if (selectedValue == _selectedValue) {
      // 같은 값이면 바로 완료
      Navigator.of(context).pop(selectedValue);
    } else {
      // 다른 값이면 이동 (애니메이션 최소화)
      _selectedValue = selectedValue;
      if (mounted) setState(() {});

      _wheelController.animateToItem(
        index,
        duration: const Duration(milliseconds: 150), // 기존 250ms에서 단축
        curve: Curves.easeOut,
      );

      // 콜백 호출
      widget.onSelect(_selectedValue);
    }
  }

  // 스크롤 변경 (디바운싱 적용)
  void _onScrollChanged(int index) {
    if (index >= 0 && index < _values.length) {
      final newValue = _values[index];

      if (newValue != _selectedValue) {
        _selectedValue = newValue;

        // setState 디바운싱
        _selectionDebouncer?.cancel();
        _selectionDebouncer = Timer(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {});
            widget.onSelect(_selectedValue);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: widget.title,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedValue),
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
                  '${widget.title}을 선택해주세요',
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
                        if (index < 0 || index >= _values.length) {
                          return const SizedBox.shrink();
                        }

                        final value = _values[index];
                        final isSelected = _selectedValue == value;

                        return GestureDetector(
                          onTap: () => _selectItem(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            child: Text(
                              '$value${widget.unit}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: isSelected ? 18.sp : 16.sp,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _values.length,
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