import 'package:flutter/material.dart';
import '../jazmine_calendar_theme.dart';

class ModernTheme extends JazmineCalendarTheme {
  const ModernTheme()
      : super(
          // Seed color - Material 3 primary color
          seedColor: const Color(0xFF2196F3),    // Blue primary
          
          gridLineColor: const Color(0x26808080),
          gridLineColorLight: const Color(0x1A808080),
          gridLineColorDark: const Color(0x1AFFFFFF),
          
          selectedDayColor: const Color(0x262196F3), // blue with 15% opacity
          selectedDayColorLight:
              const Color(0x1A2196F3), // blue with 10% opacity
          selectedDayColorDark:
              const Color(0x332196F3), // blue with 20% opacity

          weekdayHeaderStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.5,
          ),

          monthViewTheme: const MonthViewTheme(
            trailingDaysColor: Colors.grey,
            trailingDaysColorDark: Colors.grey,
          ),

          hoverColor: const Color(0x0D2196F3), // blue with 5% opacity
          hoverColorLight: const Color(0x082196F3), // blue with 3% opacity
          hoverColorDark: const Color(0x122196F3), // blue with 7% opacity
        );
}
