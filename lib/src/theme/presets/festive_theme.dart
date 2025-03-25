import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';


/// A festive-themed calendar style that uses vibrant pinks and gold accents.
///
/// This theme implements a playful and celebratory design with:
/// * Pink primary colors ([Color(0xFFFF4081)]) for main elements
/// * Gold accents ([Color(0xFFFFD700)]) for grid lines and events
/// * Subtle opacity variations for visual depth
/// * Distinctive typography with increased letter spacing
///
/// Example usage:
/// ```dart
/// JazmineCalendar(
///   theme: const FestiveTheme(),
///   // ... other calendar properties
/// )
/// ```
///
/// This theme is particularly suitable for:
/// * Holiday calendars
/// * Event planning applications
/// * Celebration-focused interfaces
class FestiveTheme extends JazmineCalendarTheme {
  /// Creates a festive theme for the Jazmine Calendar.
  ///
  /// This theme uses a vibrant pink ([Color(0xFFFF4081)]) as its primary color,
  /// complemented by gold accents ([Color(0xFFFFD700)]) throughout the calendar.
  ///
  /// The theme includes:
  /// * Grid lines in gold with varying opacities (10%, 8%, 15%)
  /// * Selected day highlighting in pink with varying opacities (15%, 10%, 20%)
  /// * Event text in gold ([Color(0xFFFFD700)])
  /// * Event backgrounds with subtle gold tinting
  /// * Custom typography with increased letter spacing for headers
  /// * Festive hover effects with gold sparkle
  /// * All-day event sections with pink backgrounds
  ///
  /// Example usage:
  /// ```dart
  /// JazmineCalendar(
  ///   theme: const FestiveTheme(),
  ///   controller: myController,
  ///   showNavigationBar: true,
  /// )
  /// ```
  ///
  /// All colors and styles are pre-configured for optimal festive appearance,
  /// but can be customized using [copyWith] if needed.
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
            trailingDaysColor: Color(0x61000000),         // black with 38% opacity
            trailingDaysColorDark: Color(0x61FFFFFF),     // white with 38% opacity
            weekdayHeaderStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            cellDateStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            eventTitleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFFFD700),  // gold
            ),
            moreEventsStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFF4081),  // festive pink
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
    Color? allDayBackgroundColor,
    Color? allDayBackgroundColorLight,
    Color? allDayBackgroundColorDark,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
    Color? currentTimeIndicatorColor,
    Color? currentTimeIndicatorColorLight,
    Color? currentTimeIndicatorColorDark,
  }) {
    return JazmineCalendarTheme(
      seedColor: seedColor ?? this.seedColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      gridLineColorLight: gridLineColorLight ?? this.gridLineColorLight,
      gridLineColorDark: gridLineColorDark ?? this.gridLineColorDark,
      selectedDayColor: selectedDayColor ?? this.selectedDayColor,
      selectedDayColorLight: selectedDayColorLight ?? this.selectedDayColorLight,
      selectedDayColorDark: selectedDayColorDark ?? this.selectedDayColorDark,
      weekdayHeaderStyle: weekdayHeaderStyle ?? this.weekdayHeaderStyle,
      dateTextStyle: dateTextStyle ?? this.dateTextStyle,
      timeTextStyle: timeTextStyle ?? this.timeTextStyle,
      monthViewTheme: monthViewTheme ?? this.monthViewTheme,
      eventBackgroundColor: eventBackgroundColor ?? this.eventBackgroundColor,
      eventBackgroundColorLight: eventBackgroundColorLight ?? this.eventBackgroundColorLight,
      eventBackgroundColorDark: eventBackgroundColorDark ?? this.eventBackgroundColorDark,
      hoverColor: hoverColor ?? this.hoverColor,
      hoverColorLight: hoverColorLight ?? this.hoverColorLight,
      hoverColorDark: hoverColorDark ?? this.hoverColorDark,
      todayIndicatorTextColor: todayIndicatorTextColor ?? this.todayIndicatorTextColor,
      todayIndicatorTextColorLight: todayIndicatorTextColorLight ?? this.todayIndicatorTextColorLight,
      todayIndicatorTextColorDark: todayIndicatorTextColorDark ?? this.todayIndicatorTextColorDark,
      allDayBackgroundColor: allDayBackgroundColor ?? this.allDayBackgroundColor,
      allDayBackgroundColorLight: allDayBackgroundColorLight ?? this.allDayBackgroundColorLight,
      allDayBackgroundColorDark: allDayBackgroundColorDark ?? this.allDayBackgroundColorDark,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      eventTimeStyle: eventTimeStyle ?? this.eventTimeStyle,
      currentTimeIndicatorColor: currentTimeIndicatorColor ?? this.currentTimeIndicatorColor,
      currentTimeIndicatorColorLight: currentTimeIndicatorColorLight ?? this.currentTimeIndicatorColorLight,
      currentTimeIndicatorColorDark: currentTimeIndicatorColorDark ?? this.currentTimeIndicatorColorDark,
    );
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
