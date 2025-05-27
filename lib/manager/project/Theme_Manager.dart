import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeManager {
  // 메인 컬러 팔레트 - 청량하고 트렌디한 컬러들
  static const Color primaryColor = Color(0xFF00C4B4); // 메인 청록색
  static const Color secondaryColor = Color(0xFF27B3A0); // 서브 청록색
  static const Color accentColor = Color(0xFF3ECEDC); // 포인트 하늘색
  static const Color accentLight = Color(0xFF5CDDDA); // 밝은 포인트색
  static const Color freshBlue = Color(0xFF0AB3FD); // 시원한 블루
  static const Color violetAccent = Color(0xFF9379FF); // 보라색 포인트
  static const Color warmAccent = Color(0xFFFFA26B); // 따뜻한 포인트 (대비)

  // 그레이스케일 팔레트 - 더 세련된 그레이 톤
  static const Color lightGrey = Color(0xFFF7F7F9);
  static const Color mediumGrey = Color(0xFFECECF0);
  static const Color darkGrey = Color(0xFF9696A0);
  static const Color nearBlack = Color(0xFF353542);

  // 상태 컬러 - 더 트렌디한 톤
  static const Color successColor = Color(0xFF00CC9C); // 성공
  static const Color errorColor = Color(0xFFFF5D6E); // 에러
  static const Color warningColor = Color(0xFFFFBE0B); // 경고
  static const Color infoColor = Color(0xFF3DB9EC); // 정보

  // Light 모드 ColorScheme (Material 3)
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: primaryColor,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: primaryColor.withValues(alpha: 0.1),
    onPrimaryContainer: primaryColor.withValues(alpha: 0.8),
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: secondaryColor.withValues(alpha: 0.1),
    onSecondaryContainer: secondaryColor.withValues(alpha: 0.8),
    tertiary: accentColor,
    onTertiary: Colors.white,
    tertiaryContainer: accentColor.withValues(alpha: 0.1),
    onTertiaryContainer: accentColor.withValues(alpha: 0.8),
    error: errorColor,
    onError: Colors.white,
    errorContainer: errorColor.withValues(alpha: 0.1),
    onErrorContainer: errorColor.withValues(alpha: 0.8),
    surface: Colors.white,
    onSurface: nearBlack,
    surfaceContainerHighest: lightGrey,
    onSurfaceVariant: darkGrey,
    outline: darkGrey.withValues(alpha: 0.5),
    outlineVariant: darkGrey.withValues(alpha: 0.2),
    shadow: Colors.black.withValues(alpha: 0.1),
    scrim: Colors.black.withValues(alpha: 0.2),
    inverseSurface: nearBlack,
    onInverseSurface: Colors.white,
    inversePrimary: accentLight,
  );


  // Dark 모드 ColorScheme (Material 3)
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primaryColor,
    primary: accentLight, // 다크 모드에서는 더 밝은 버전 사용
    onPrimary: Colors.black,
    primaryContainer: accentLight.withValues(alpha: 0.15),
    onPrimaryContainer: accentLight.withValues(alpha: 0.8),
    secondary: accentColor,
    onSecondary: Colors.black,
    secondaryContainer: accentColor.withValues(alpha: 0.15),
    onSecondaryContainer: accentColor.withValues(alpha: 0.8),
    tertiary: freshBlue,
    onTertiary: Colors.white,
    tertiaryContainer: freshBlue.withValues(alpha: 0.15),
    onTertiaryContainer: freshBlue.withValues(alpha: 0.8),
    error: errorColor,
    onError: Colors.black,
    errorContainer: errorColor.withValues(alpha: 0.15),
    onErrorContainer: errorColor.withValues(alpha: 0.8),
    surface: const Color(0xFF1C1C24),
    onSurface: Colors.white,
    surfaceContainerHighest: const Color(0xFF2A2A36),
    onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
    outline: Colors.white.withValues(alpha: 0.3),
    outlineVariant: Colors.white.withValues(alpha: 0.1),
    shadow: Colors.black.withValues(alpha: 0.3),
    scrim: Colors.black.withValues(alpha: 0.4),
    inverseSurface: Colors.white,
    onInverseSurface: nearBlack,
    inversePrimary: primaryColor,
  );



  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'pre',
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightGrey,
    cardColor: Colors.white,
    canvasColor: Colors.white,
    secondaryHeaderColor: nearBlack,
    dividerTheme: DividerThemeData(
      thickness: 0.5,
      color: darkGrey.withValues(alpha: 0.3),
    ),
    iconTheme: const IconThemeData(color: secondaryColor),
    textTheme: koreanTextTheme,
    shadowColor: const Color(0x1A000000),

    // 앱바 테마 향상
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: nearBlack,
      elevation: 0,
      shadowColor: const Color(0x1A000000),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: nearBlack),
      toolbarHeight: 60.h,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
      ),
    ),

    // 버튼 테마 강화
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 0,
        minimumSize: Size(88.w, 48.h),
        textStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 텍스트 버튼 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 아웃라인 버튼 테마
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: Size(88.w, 48.h),
        textStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: TextStyle(color: darkGrey, fontSize: 14.sp),
      labelStyle: TextStyle(color: nearBlack, fontSize: 14.sp),
      errorStyle: TextStyle(color: errorColor, fontSize: 14.sp),
    ),

    // 카드 테마
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0),
    ),

    // 플로팅 액션 버튼 테마
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 4,
      highlightElevation: 8,
    ),

    // 바텀 네비게이션 바 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
    ),

    // 스위치 테마
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha:0.4);
        }
        return darkGrey.withValues(alpha:0.3);
      }),
    ),

    // 슬라이더 테마
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: darkGrey.withValues(alpha:0.3),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withValues(alpha:0.2),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),

    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
    ),

    // 라디오 버튼 테마
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return darkGrey;
      }),
    ),

    // 진행 표시기 테마
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: darkGrey.withValues(alpha:0.2),
      circularTrackColor: darkGrey.withValues(alpha:0.2),
    ),

    colorScheme: lightColorScheme,

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      backgroundColor: nearBlack.withValues(alpha:0.9),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        height: 1.3.h,
      ),
      actionTextColor: accentLight,
    ),

    // 모달 바텀시트 테마
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // 다이얼로그 테마
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: nearBlack,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: nearBlack.withValues(alpha:0.8),
        fontSize: 15.sp,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'pre',
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF101014),
    secondaryHeaderColor: Colors.white.withValues(alpha: 0.9),
    cardColor: const Color(0xFF1C1C24),
    canvasColor: const Color(0xFF1C1C24),
    dividerTheme: DividerThemeData(
      thickness: 0.5,
      color: Colors.white.withValues(alpha: 0.1),
    ),
    iconTheme: const IconThemeData(color: accentLight),
    textTheme: koreanDarkTextTheme,
    shadowColor: const Color(0x1AFFFFFF),

    // 앱바 테마 향상
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1C1C24),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x1AFFFFFF),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
      toolbarHeight: 60.h,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    ),

    // 버튼 테마 강화
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 0,
        minimumSize: Size(88.w, 48.h),
        textStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 텍스트 버튼 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentLight,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 아웃라인 버튼 테마
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentLight,
        side: const BorderSide(color: accentLight, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: Size(88.w, 48.h),
        textStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A36),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: accentLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 14.sp),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.9), fontSize: 14.sp),
      errorStyle: TextStyle(color: errorColor, fontSize: 12.sp),
    ),

    // 카드 테마
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 0.w),
    ),

    // 플로팅 액션 버튼 테마
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 4,
      highlightElevation: 8,
    ),

    // 바텀 네비게이션 바 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1C1C24),
      selectedItemColor: accentLight,
      unselectedItemColor: Colors.white.withValues(alpha:0.5),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
    ),

    // 스위치 테마
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight.withValues(alpha:0.4);
        }
        return Colors.white.withValues(alpha:0.3);
      }),
    ),

    // 슬라이더 테마
    sliderTheme: SliderThemeData(
      activeTrackColor: accentLight,
      inactiveTrackColor: Colors.white.withValues(alpha:0.3),
      thumbColor: accentLight,
      overlayColor: accentLight.withValues(alpha:0.2),
      valueIndicatorColor: accentLight,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
    ),

    // 라디오 버튼 테마
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return Colors.white.withValues(alpha:0.6);
      }),
    ),

    // 진행 표시기 테마
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentLight,
      linearTrackColor: Colors.white.withValues(alpha:0.2),
      circularTrackColor: Colors.white.withValues(alpha:0.2),
    ),

    colorScheme: darkColorScheme,

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      backgroundColor: const Color(0xFF2A2A36),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        height: 1.3,
      ),
      actionTextColor: accentLight,
    ),

    // 모달 바텀시트 테마
    bottomSheetTheme:  BottomSheetThemeData(
      backgroundColor: Color(0xFF1C1C24),
      modalBackgroundColor: Color(0xFF1C1C24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // 다이얼로그 테마
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1C1C24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.white.withValues(alpha:0.8),
        fontSize: 15.sp,
      ),
    ),
  );

  static final TextTheme koreanTextTheme = TextTheme(
    // ✅ 헤드라인 (섹션 최상단 타이틀)
    headlineLarge: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, height: 1.3, letterSpacing: -0.2),
    headlineMedium:  TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, height: 1.3, letterSpacing: -0.2),
    headlineSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.1),

    // ✅ 디스플레이 (브랜드 슬로건, Hero 영역)
    displayLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.3),
    displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.2),
    displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.1),

    // ✅ 타이틀 (섹션 제목, 리스트 헤더)
    titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, letterSpacing: -0.1),
    titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, letterSpacing: -0.1),
    titleSmall: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),

    // ✅ 본문 (일반 텍스트, 설명)
    bodyLarge: TextStyle(fontSize: 16.sp, height: 1.5, color: nearBlack, letterSpacing: -0.1),
    bodyMedium: TextStyle(fontSize: 14.sp, height: 1.5, color: nearBlack, letterSpacing: -0.1),
    bodySmall: TextStyle(fontSize: 12.sp, height: 1.4, color: nearBlack),

    // ✅ 라벨 (버튼, 태그, 뱃지 등)
    labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400),
    labelSmall: TextStyle(fontSize: 11.sp, color: nearBlack),
  );

  static final TextTheme koreanDarkTextTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white, letterSpacing: -0.2),
    headlineMedium: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white, letterSpacing: -0.2),
    headlineSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, height: 1.3, color: Colors.white, letterSpacing: -0.1),

    displayLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white, letterSpacing: -0.3),
    displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white, letterSpacing: -0.2),
    displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, height: 1.2, color: Colors.white, letterSpacing: -0.1),

    titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.1),
    titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: -0.1),
    titleSmall: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white),

    bodyLarge:  TextStyle(fontSize: 16.sp, height: 1.5, color: Colors.white, letterSpacing: -0.1),
    bodyMedium: TextStyle(fontSize: 14.sp, height: 1.5, color: Colors.white.withValues(alpha:0.9), letterSpacing: -0.1),
    bodySmall: TextStyle(fontSize: 12.sp, height: 1.4, color: Colors.white.withValues(alpha:0.7)),

    labelLarge:  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white),
    labelMedium: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha:0.9)),
    labelSmall: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha:0.6)),
  );

  // 그라데이션 스타일 - 앱에서 편리하게 사용할 수 있는 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolGradient = LinearGradient(
    colors: [accentColor, freshBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [accentLight, warmAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [freshBlue, violetAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}