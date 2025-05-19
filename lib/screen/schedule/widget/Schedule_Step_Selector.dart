import '../../../manager/project/Import_Manager.dart';
import 'package:flutter/material.dart';

class ScheduleStepSelector extends StatefulWidget {
  final int currentStep;
  final int viewStep;
  final int totalSteps;
  final List<String> stepTitles;
  final void Function(int index) onStepTap;

  const ScheduleStepSelector({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.onStepTap,
    required this.viewStep,
  });

  @override
  State<ScheduleStepSelector> createState() => _ScheduleStepSelectorState();
}

class _ScheduleStepSelectorState extends State<ScheduleStepSelector> with SingleTickerProviderStateMixin {
  // 애니메이션 컨트롤러 추가
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateProgressAnimation();
  }

  @override
  void didUpdateWidget(ScheduleStepSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewStep != widget.viewStep || oldWidget.currentStep != widget.currentStep) {
      _updateProgressAnimation();
    }
  }

  void _updateProgressAnimation() {
    // 프로그레스 애니메이션 업데이트
    final double beginValue = widget.viewStep > 0 ?
    ((widget.viewStep - 1) / (widget.totalSteps - 1)) : 0.0;
    final double endValue = widget.viewStep / (widget.totalSteps - 1);

    _progressAnimation = Tween<double>(
      begin: beginValue,
      end: endValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // 더 부드러운 커브 사용
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final lineColor = theme.highlightColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // 총 스텝 간격 계산
          final stepWidth = (MediaQuery.of(context).size.width - 32) / (widget.totalSteps - 1);
          // 현재 위치까지의 너비 계산
          final progressWidth = stepWidth * _progressAnimation.value * (widget.totalSteps - 1);

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              // 배경 줄
              Container(
                height: 4,
                margin: const EdgeInsets.only(top: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lineColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 진행 애니메이션 줄 - 메인 프로그레스 바
              if (widget.viewStep > 0)
                Positioned(
                  left: 0,
                  top: 15,
                  child: Container(
                    height: 4,
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

              // 진행 애니메이션 끝 효과 (발광 효과)
              if (widget.viewStep > 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  left: progressWidth - 6,
                  top: 12,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

              // 단계 표시기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.totalSteps, (index) {
                  final isCompleted = index < widget.viewStep;
                  final isCurrent = index == widget.currentStep;

                  return IntrinsicWidth(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          color: backgroundColor,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onStepTap(index),
                              borderRadius: BorderRadius.circular(10),
                              splashColor: color.withValues(alpha: 0.3),
                              highlightColor: color.withValues(alpha: 0.1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutQuart,
                                width: isCurrent ? 36 : 30,
                                height: isCurrent ? 36 : 30,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? color
                                      : isCurrent
                                      ? color.withValues(alpha: 0.15)
                                      : lineColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCompleted || isCurrent ? color : lineColor.withValues(alpha: 0.5),
                                    width: isCurrent ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isCurrent ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check_rounded
                                          : isCurrent
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      key: ValueKey('step_icon_$index${isCompleted ? '_completed' : isCurrent ? '_current' : ''}'),
                                      size: isCurrent ? 20 : 16,
                                      color: isCompleted
                                          ? Colors.white
                                          : isCurrent
                                          ? color
                                          : lineColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0.8,
                            end: isCurrent ? 1.0 : 0.9,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Text(
                            widget.stepTitles[index],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isCurrent ? color : isCompleted ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                              fontWeight: isCurrent ? FontWeight.bold : isCompleted ? FontWeight.w500 : FontWeight.normal,
                              fontSize: isCurrent ? 14 : 13,
                              letterSpacing: isCurrent ? 0.2 : 0,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}