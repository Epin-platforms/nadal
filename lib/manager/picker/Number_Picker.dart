import '../project/Import_Manager.dart';

class NumberPicker extends StatefulWidget {
  const NumberPicker({
    super.key,
    this.minValue = 0,
    this.maxValue = 100,
    required this.onSelect,
    this.initialValue,
  });

  final int minValue;
  final int maxValue;
  final int? initialValue;
  final void Function(int value) onSelect;

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late FixedExtentScrollController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialValue ?? widget.minValue;
    _controller = FixedExtentScrollController(initialItem: _currentIndex - widget.minValue);
  }

  void _jumpToIndex(int index) {
    _controller.animateToItem(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.maxValue - widget.minValue + 1;
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 28,
      diameterRatio: 1.2,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          _currentIndex = index + widget.minValue;
        });
        widget.onSelect(_currentIndex);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final value = widget.minValue + index;
          final isSelected = value == _currentIndex;
          return GestureDetector(
            onTap: () => _jumpToIndex(index),
            child: Center(
              child: Text(
                '$value 년',
                style: TextStyle(
                  fontSize: isSelected ? 17 : 13,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
