import 'package:flutter/material.dart';
import '../jazmine_calendar_theme.dart';

class FestiveTheme extends JazmineCalendarTheme {
  const FestiveTheme()
      : super(
          // Seed color - Material 3 primary color
          seedColor: const Color(0xFFFF4081),    // Festive pink primary
          
          // Grid lines - subtle gold tones
          gridLineColor: const Color(0x1AFFD700),        // gold with 10% opacity
          gridLineColorLight: const Color(0x14FFD700),    // gold with 8% opacity
          gridLineColorDark: const Color(0x26FFD700),     // gold with 15% opacity
          
          // Selected day - festive red tones
          selectedDayColor: const Color(0x26FF4081),      // pink with 15% opacity
          selectedDayColorLight: const Color(0x1AFF4081),  // pink with 10% opacity
          selectedDayColorDark: const Color(0x33FF4081),   // pink with 20% opacity
          
          // Today indicator colors - bright and festive
          todayIndicatorColor: const Color(0xFFFF4081),    // solid pink
          todayIndicatorColorLight: const Color(0xFFFF4081), // solid pink
          todayIndicatorColorDark: const Color(0xFFFF80AB),  // light pink
          
          // Event colors
          eventTextColor: const Color(0xFFFFD700),        // gold
          eventTextColorLight: const Color(0xFFB8860B),   // dark golden
          eventTextColorDark: const Color(0xFFFFD700),    // gold
          
          // Event background colors
          eventBackgroundColor: const Color(0x1AFFD700),  // gold with 10% opacity
          eventBackgroundColorLight: const Color(0x14FFD700), // gold with 8% opacity
          eventBackgroundColorDark: const Color(0x26FFD700),  // gold with 15% opacity
          
          // Text styles with festive flair
          weekdayHeaderStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.8,
            height: 1.2,
            color: Color(0xFFFF4081), // festive pink
          ),
          
          dateTextStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          
          timeTextStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFFFF4081), // festive pink
          ),
          
          // Month view specific theme
          monthViewTheme: const MonthViewTheme(
            trailingDaysColor: Color(0x99FF80AB),        // light pink with 60% opacity
            trailingDaysColorDark: Color(0x99FF80AB),    // light pink with 60% opacity
            trailingDaysTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          // Hover effects with sparkle
          hoverColor: const Color(0x1AFFD700),           // gold with 10% opacity
          hoverColorLight: const Color(0x14FFD700),      // gold with 8% opacity
          hoverColorDark: const Color(0x26FFD700),       // gold with 15% opacity
          
          // Today indicator text colors
          todayIndicatorTextColor: Colors.white,
          todayIndicatorTextColorLight: Colors.white,
          todayIndicatorTextColorDark: const Color(0xFF1C1B1F),
        );

  @override
  JazmineCalendarTheme copyWith({
    Color? seedColor,
    Color? gridLineColor,
    Color? gridLineColorLight,
    Color? gridLineColorDark,
    Color? selectedDayColor,
    Color? selectedDayColorLight,
    Color? selectedDayColorDark,
    TextStyle? weekdayHeaderStyle,
    TextStyle? dateTextStyle,
    TextStyle? timeTextStyle,
    MonthViewTheme? monthViewTheme,
    Color? eventBackgroundColor,
    Color? eventBackgroundColorLight,
    Color? eventBackgroundColorDark,
    Color? hoverColor,
    Color? hoverColorLight,
    Color? hoverColorDark,
    Color? todayIndicatorTextColor,
    Color? todayIndicatorTextColorLight,
    Color? todayIndicatorTextColorDark,
  }) {
    return const FestiveTheme();  // For simplicity, return a new instance
  }

  @override
  ThemeExtension<JazmineCalendarTheme> lerp(
    ThemeExtension<JazmineCalendarTheme>? other,
    double t,
  ) {
    if (other is! FestiveTheme) {
      return this;
    }
    return this;  // For simplicity, return this instance
  }
}
