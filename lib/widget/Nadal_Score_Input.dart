import '../manager/project/Import_Manager.dart';

class NadalScoreInput extends StatefulWidget {
  const NadalScoreInput({super.key, required this.currentScore, required this.finalScore});
  final int currentScore;
  final int finalScore;

  @override
  State<NadalScoreInput> createState() => _NadalScoreInputState();
}

class _NadalScoreInputState extends State<NadalScoreInput> {
  late FixedExtentScrollController _wheelController;
  late int tempScore;

  static const int loopBase = 5000;

  @override
  void initState() {
    super.initState();
    _wheelController = FixedExtentScrollController(initialItem: loopBase + widget.currentScore);
    tempScore = widget.currentScore;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).cardColor
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text("이번 세트에서 몇 게임을 이기셨나요?", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40.h,
                      diameterRatio: 1.1,
                      physics: const FixedExtentScrollPhysics(),
                      controller: _wheelController,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          tempScore = index % (widget.finalScore + 1);
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 10000,
                        builder: (context, index) {
                          final displayScore = index % (widget.finalScore + 1);
                          final isSelected = tempScore == displayScore;
                          return Center(
                            child: GestureDetector(
                              onTap: (){
                                final targetIndex = index - (index % (widget.finalScore + 1)) + displayScore;
                                _wheelController.animateToItem(
                                  targetIndex,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Text(
                                '$displayScore',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).hintColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24,),
          NadalButton(isActive: true, title: '확인', onPressed: ()=> Navigator.pop(context, tempScore),),
        ],
      ),
    );
  }
}
