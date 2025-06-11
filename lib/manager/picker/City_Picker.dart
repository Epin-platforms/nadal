import '../project/Import_Manager.dart';

class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.local, this.initCity});
  final String local;
  final String? initCity;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  late List<String> _cities;
  late String _selectedCity;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();

    // 안전성을 위한 null 체크 및 기본값 처리
    final localData = ListPackage.local[widget.local];
    if (localData == null || localData.isEmpty) {
      _cities = ['데이터 없음'];
      _selectedCity = '데이터 없음';
    } else {
      _cities = localData.toList();
      _selectedCity = widget.initCity ?? _cities.first;
    }

    final initialIndex = _cities.indexOf(_selectedCity);
    _wheelController = FixedExtentScrollController(
        initialItem: initialIndex.clamp(0, _cities.length - 1)
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    if (index < 0 || index >= _cities.length) return;

    final selectedItem = _cities[index];
    if (selectedItem == _selectedCity) {
      // 데이터가 없는 경우 null 반환
      final result = selectedItem == '데이터 없음' ? null : selectedItem;
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _selectedCity = selectedItem;
      });
      _wheelController.animateToItem(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScrollChanged(int index) {
    if (index >= 0 && index < _cities.length) {
      setState(() {
        _selectedCity = _cities[index];
      });
    }
  }

  void _confirmSelection() {
    final result = _selectedCity == '데이터 없음' ? null : _selectedCity;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValidData = _cities.first != '데이터 없음';

    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '시/구/군 선택',
          actions: [
            TextButton(
              onPressed: hasValidData ? _confirmSelection : null,
              child: Text(
                '확인',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: hasValidData
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(100),
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

                // 제목 및 지역 정보
                Column(
                  children: [
                    Text(
                      '시/구/군을 선택해주세요',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.local,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 60.h),

                // 데이터 없음 메시지 또는 휠 스크롤뷰
                if (!hasValidData)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48.r,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '해당 지역의\n시/구/군 정보가 없습니다',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _wheelController,
                      itemExtent: 50.h,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: _onScrollChanged,
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final isSelected = _selectedCity == _cities[index];

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
                                _cities[index],
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
                        childCount: _cities.length,
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