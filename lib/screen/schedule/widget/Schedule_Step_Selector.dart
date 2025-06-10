import '../../../manager/project/Import_Manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScheduleStepSelector extends StatelessWidget {
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

  double _calculateProgressWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final stepWidth = (screenWidth - 32.w) / (totalSteps - 1);
    return stepWidth * viewStep.clamp(0, totalSteps - 1);
  }

  bool _isStepCompleted(int index) {
    // 마지막 단계까지 포함하여 완료 상태 확인
    return index < viewStep || (index == viewStep && viewStep == totalSteps - 1);
  }

  bool _isCurrentStep(int index) {
    return index == currentStep;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final lineColor = theme.highlightColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 배경 줄
          Container(
            height: 4.h,
            margin: EdgeInsets.only(top: 15.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: lineColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // 진행 상태 표시 줄
          if (viewStep > 0)
            Positioned(
              left: 0,
              top: 15.h,
              child: Container(
                height: 4.h,
                width: _calculateProgressWidth(context),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

          // 단계 표시기
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isCompleted = _isStepCompleted(index);
              final isCurrent = _isCurrentStep(index);

              return IntrinsicWidth(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      color: backgroundColor,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onStepTap(index),
                          borderRadius: BorderRadius.circular(10.r),
                          splashColor: color.withValues(alpha: 0.3),
                          highlightColor: color.withValues(alpha: 0.1),
                          child: Container(
                            width: isCurrent ? 36.w : 30.w,
                            height: isCurrent ? 36.h : 30.h,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? color
                                  : isCurrent
                                  ? color.withValues(alpha: 0.15)
                                  : lineColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isCompleted || isCurrent
                                    ? color
                                    : lineColor.withValues(alpha: 0.5),
                                width: isCurrent ? 2.5.w : 1.5.w,
                              ),
                              boxShadow: isCurrent ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Icon(
                                _getStepIcon(index, isCompleted, isCurrent),
                                size: isCurrent ? 20.sp : 16.sp,
                                color: _getStepIconColor(
                                    isCompleted,
                                    isCurrent,
                                    color,
                                    lineColor
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      stepTitles[index],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getStepTextColor(
                            isCompleted,
                            isCurrent,
                            color,
                            theme
                        ),
                        fontWeight: _getStepTextWeight(isCompleted, isCurrent),
                        fontSize: isCurrent ? 14.sp : 13.sp,
                        letterSpacing: isCurrent ? 0.2 : 0,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(int index, bool isCompleted, bool isCurrent) {
    if (isCompleted) {
      return Icons.check_rounded;
    } else if (isCurrent) {
      return Icons.radio_button_checked_rounded;
    } else {
      return Icons.radio_button_unchecked_rounded;
    }
  }

  Color _getStepIconColor(
      bool isCompleted,
      bool isCurrent,
      Color primaryColor,
      Color lineColor
      ) {
    if (isCompleted) {
      return Colors.white;
    } else if (isCurrent) {
      return primaryColor;
    } else {
      return lineColor.withValues(alpha: 0.7);
    }
  }

  Color _getStepTextColor(
      bool isCompleted,
      bool isCurrent,
      Color primaryColor,
      ThemeData theme
      ) {
    if (isCurrent) {
      return primaryColor;
    } else if (isCompleted) {
      return theme.textTheme.bodyMedium?.color ?? Colors.black;
    } else {
      return theme.hintColor;
    }
  }

  FontWeight _getStepTextWeight(bool isCompleted, bool isCurrent) {
    if (isCurrent) {
      return FontWeight.bold;
    } else if (isCompleted) {
      return FontWeight.w500;
    } else {
      return FontWeight.normal;
    }
  }
}