import '../../../manager/project/Import_Manager.dart';

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

  final currentColor = ThemeManager.freshBlue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
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
                  color: primaryColor,
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
                          splashColor: primaryColor.withValues(alpha: 0.3),
                          highlightColor: primaryColor.withValues(alpha: 0.1),
                          child: Container(
                            width: isCurrent ? 40.w : 30.w,
                            height: isCurrent ? 40.h : 30.h,
                            decoration: BoxDecoration(
                              // 현재 스텝은 코랄 오렌지 배경, 완료된 스텝은 primary, 나머지는 연한 배경
                              color: isCurrent
                                  ? currentColor // 현재 스텝만 코랄 오렌지 배경
                                  : isCompleted
                                  ? primaryColor
                                  : lineColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isCurrent
                                    ? currentColor // 현재 스텝 테두리도 코랄 오렌지
                                    : isCompleted
                                    ? primaryColor
                                    : lineColor.withValues(alpha: 0.5),
                                width: isCurrent ? 3.w : 1.5.w,
                              ),
                              boxShadow: isCurrent ? [
                                BoxShadow(
                                  color: currentColor.withValues(alpha: 0.4), // 코랄 오렌지 그림자
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                  spreadRadius: 2.r,
                                ),
                                BoxShadow(
                                  color: currentColor.withValues(alpha: 0.2), // 코랄 오렌지 외곽 그림자
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                  spreadRadius: 4.r,
                                ),
                              ] : isCompleted ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Icon(
                                _getStepIcon(index, isCompleted, isCurrent),
                                size: isCurrent ? 22.sp : 16.sp,
                                color: _getStepIconColor(
                                    isCompleted,
                                    isCurrent,
                                    primaryColor,
                                    onPrimaryColor,
                                    lineColor
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      stepTitles[index],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getStepTextColor(
                            isCompleted,
                            isCurrent,
                            primaryColor,
                            theme
                        ),
                        fontWeight: _getStepTextWeight(isCompleted, isCurrent),
                        fontSize: isCurrent ? 15.sp : 13.sp,
                        letterSpacing: isCurrent ? 0.3 : 0,
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
    if (isCompleted && !isCurrent) {
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
      Color onPrimaryColor,
      Color lineColor
      ) {
    if (isCurrent) {
      // 현재 스텝: 코랄 오렌지 배경에 흰색 아이콘 (최고 대비)
      return Colors.white;
    } else if (isCompleted) {
      // 완료된 스텝: primary 배경에 onPrimary 색상
      return onPrimaryColor;
    } else {
      // 미완료 스텝: 연한 배경에 연한 색상
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
      // 현재 스텝 텍스트: 코랄 오렌지 색상으로 강조
      return currentColor;
    } else if (isCompleted) {
      // 완료된 스텝 텍스트: 일반 텍스트 색상
      return theme.textTheme.bodyMedium?.color ?? Colors.black;
    } else {
      // 미완료 스텝 텍스트: 연한 색상
      return theme.hintColor;
    }
  }

  FontWeight _getStepTextWeight(bool isCompleted, bool isCurrent) {
    if (isCurrent) {
      // 현재 스텝: 더 굵은 폰트
      return FontWeight.w800;
    } else if (isCompleted) {
      return FontWeight.w600;
    } else {
      return FontWeight.w400;
    }
  }
}