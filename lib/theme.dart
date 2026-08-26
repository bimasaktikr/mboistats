import 'package:flutter/material.dart';

// =============================================
// MBOIStats+ Design System v2
// =============================================

// ---- Background ----
const Color bgColor = Color(0xFFFDFAF2);

// ---- Blue Palette (Primary) ----
const Color blueLighter = Color(0xFF9FD8F2);
const Color blueLight = Color(0xFF8CD1EF);
const Color blueLightActive = Color(0xFF75C7EC);
const Color blueNormal = Color(0xFF2AA9E1); // Primary
const Color blueHover = Color(0xFF2490BF);
const Color blueActive = Color(0xFF1F7BA4);
const Color blueDark = Color(0xFF0F3B4F);
const Color blueDarkHover = Color(0xFF0B2A38);
const Color blueDarkActive = Color(0xFF051319);

// ---- Green Palette ----
const Color greenLighter = Color(0xFFC4ECCB);
const Color greenNormal = Color(0xFF7BD48B);
const Color greenDark = Color(0xFF2B4A31);

// ---- Orange Palette ----
const Color orangeNormal = Color(0xFFE8873D);

// ---- Yellow Palette ----
const Color yellowNormal = Color(0xFFE8C93D);

// ---- Legacy Colors (backward compatible) ----
Color green1 = const Color(0xFF097210);
Color green2 = const Color(0xFF00880F);

Color dark1 = const Color(0xFF1C1C1C);
Color dark2 = const Color(0xFF4A4A4A);
Color dark3 = const Color(0xFF999798);
Color dark4 = const Color(0xFFEDEDED);

Color blue1 = const Color(0xFF0281A0);
Color blue2 = const Color(0xFF00AED5);
Color blue3 = const Color(0xFF38BBDA);

Color red = const Color(0xFFED2739);
Color purple = const Color(0xFF87027B);

// ---- Header Gradient ----
const Color headerTealStart = Color(0xFF2490BF);
const Color headerTealEnd = Color(0xFF2AA9E1);

// ---- Kontak Card Background ----
const Color kontakHeaderBg = Color(0xFFFFF8ED);

// =============================================
// Typography — Plus Jakarta Sans
// =============================================
const String _fontFamily = 'PlusJakartaSans';

// Regular (400)
const TextStyle pjsRegular12 = TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400);
const TextStyle pjsRegular14 = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400);
const TextStyle pjsRegular16 = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400);

// Medium (500)
const TextStyle pjsMedium12 = TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500);
const TextStyle pjsMedium14 = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500);
const TextStyle pjsMedium16 = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500);

// SemiBold (600)
const TextStyle pjsSemiBold12 = TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600);
const TextStyle pjsSemiBold14 = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600);
const TextStyle pjsSemiBold16 = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600);
const TextStyle pjsSemiBold18 = TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600);

// Bold (700)
const TextStyle pjsBold14 = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w700);
const TextStyle pjsBold16 = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700);
const TextStyle pjsBold18 = TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700);
const TextStyle pjsBold20 = TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w700);
const TextStyle pjsBold24 = TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700);

// ExtraBold (800)
const TextStyle pjsExtraBold20 = TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w800);
const TextStyle pjsExtraBold24 = TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w800);

// ---- Legacy Typography (backward compatible) ----
TextStyle regular12_5 =
    const TextStyle(fontFamily: 'SF-Pro-Display', fontSize: 12.5);
TextStyle regular14 = regular12_5.copyWith(fontSize: 14);

TextStyle semibold12_5 = regular12_5.copyWith(fontWeight: FontWeight.w600);
TextStyle semibold14 = semibold12_5.copyWith(fontSize: 14, letterSpacing: 0.1);

TextStyle bold16 = regular12_5.copyWith(
    fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.1);
TextStyle bold18 = bold16.copyWith(fontSize: 18, letterSpacing: -0.5);

// =============================================
// Dark Mode Support
// =============================================
class AppThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: blueNormal,
    scaffoldBackgroundColor: bgColor,
    fontFamily: _fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: blueHover),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: blueHover,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: blueNormal,
      unselectedItemColor: Color(0xFF666666),
      selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: blueNormal,
      brightness: Brightness.light,
      surface: bgColor,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: blueNormal,
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: _fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: blueLighter),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: blueLighter,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: blueNormal,
      unselectedItemColor: Color(0xFF888888),
      selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400),
    ),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: blueNormal,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ),
  );
}
