import 'package:flutter/material.dart';
import '../jazmine_calendar_theme.dart';

class MinimalTheme extends JazmineCalendarTheme {
  const MinimalTheme()
      : super(
          // Seed color - Material 3 primary color
          seedColor: const Color(0xFF6750A4),    // M3 Purple primary
          
          // Grid lines - very subtle grey tones
          gridLineColor: const Color(0x0A000000),        // black with 4% opacity
          gridLineColorLight: const Color(0x08000000),    // black with 3% opacity
          gridLineColorDark: const Color(0x0AFFFFFF),     // white with 4% opacity
          
          // Selected day - soft purple tones
          selectedDayColor: const Color(0x1A6750A4),      // purple with 10% opacity
          selectedDayColorLight: const Color(0x146750A4),  // purple with 8% opacity
          selectedDayColorDark: const Color(0x266750A4),   // purple with 15% opacity
          
          // Today indicator colors
          todayIndicatorColor: const Color(0xFF6750A4),    // solid purple
          todayIndicatorColorLight: const Color(0xFF6750A4), // solid purple
          todayIndicatorColorDark: const Color(0xFFD0BCFF),  // light purple
          
          // Event colors
          eventTextColor: Colors.black87,
          eventTextColorLight: Colors.black87,
          eventTextColorDark: Colors.white70,
          
          // Text styles
          weekdayHeaderStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            letterSpacing: 0.5,
            height: 1.2,
          ),
          
          dateTextStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          
          timeTextStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF6750A4),
          ),
          
          // Month view specific theme
          monthViewTheme: const MonthViewTheme(
            trailingDaysColor: Color(0x61000000),         // black with 38% opacity
            trailingDaysColorDark: Color(0x61FFFFFF),     // white with 38% opacity
            trailingDaysTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
          
          // Hover effects
          hoverColor: const Color(0x086750A4),           // purple with 3% opacity
          hoverColorLight: const Color(0x066750A4),      // purple with 2% opacity
          hoverColorDark: const Color(0x0A6750A4),       // purple with 4% opacity
          
          // Today indicator text colors
          todayIndicatorTextColor: Colors.white,
          todayIndicatorTextColorLight: Colors.white,
          todayIndicatorTextColorDark: const Color(0xFF1C1B1F),
        );
}
