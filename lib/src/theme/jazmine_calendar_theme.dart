import 'package:flutter/material.dart';

// Main calendar theme for common elements
class JazmineCalendarTheme extends ThemeExtension<JazmineCalendarTheme> {
  final Color? seedColor;
  final Color? gridLineColor;
  final Color? gridLineColorLight;
  final Color? gridLineColorDark;
  
  final Color? selectedDayColor;
  final Color? selectedDayColorLight;
  final Color? selectedDayColorDark;
  
  final Color? todayIndicatorColor;
  final Color? todayIndicatorColorLight;
  final Color? todayIndicatorColorDark;
  
  final Color? eventTextColor;
  final Color? eventTextColorLight;
  final Color? eventTextColorDark;
  
  // Add these new properties
  final Color? eventBackgroundColor;
  final Color? eventBackgroundColorLight;
  final Color? eventBackgroundColorDark;
  
  final TextStyle? weekdayHeaderStyle;
  final TextStyle? dateTextStyle;
  final TextStyle? timeTextStyle;
  
  final MonthViewTheme monthViewTheme;

  final Color? hoverColor;
  final Color? hoverColorLight;
  final Color? hoverColorDark;

  final Color? todayIndicatorTextColor;
  final Color? todayIndicatorTextColorLight;
  final Color? todayIndicatorTextColorDark;

  const JazmineCalendarTheme({
    this.seedColor,
    this.gridLineColor,
    this.gridLineColorLight,
    this.gridLineColorDark,
    this.selectedDayColor,
    this.selectedDayColorLight,
    this.selectedDayColorDark,
    this.todayIndicatorColor,
    this.todayIndicatorColorLight,
    this.todayIndicatorColorDark,
    this.eventTextColor,
    this.eventTextColorLight,
    this.eventTextColorDark,
    this.eventBackgroundColor,
    this.eventBackgroundColorLight,
    this.eventBackgroundColorDark,
    this.weekdayHeaderStyle,
    this.dateTextStyle,
    this.timeTextStyle,
    this.monthViewTheme = const MonthViewTheme(),
    this.hoverColor,
    this.hoverColorLight,
    this.hoverColorDark,
    this.todayIndicatorTextColor,
    this.todayIndicatorTextColorLight,
    this.todayIndicatorTextColorDark,
  });

  Color getGridLineColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && gridLineColorLight != null) {
      return gridLineColorLight!;
    }
    if (brightness == Brightness.dark && gridLineColorDark != null) {
      return gridLineColorDark!;
    }
    if (gridLineColor != null) {
      return gridLineColor!;
    }
    
    return brightness == Brightness.light
        ? Colors.grey.withOpacity(0.2)
        : Colors.grey.withOpacity(0.3);
  }

  Color getSelectedDayColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return selectedDayColor ?? colorScheme.primary;
  }

  Color getTodayIndicatorColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return todayIndicatorColor ?? colorScheme.primary;
  }

  TextStyle getWeekdayHeaderStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return weekdayHeaderStyle ?? TextStyle(
      color: colorScheme.onSurface.withOpacity(0.7),
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle getDateTextStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return dateTextStyle ?? TextStyle(
      color: colorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle getTimeTextStyle(BuildContext context) {
    return timeTextStyle ?? Theme.of(context).textTheme.bodySmall!;
  }

  Color getEventBackgroundColor(BuildContext context) {
    // The event's own color property should be used instead of theme colors.
    // These are only fallback values when the event has no color set.
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.blue.withOpacity(0.8)
        : Colors.blue.withOpacity(0.6);
  }

  // Add a getter method for event text color
  Color getEventTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && eventTextColorLight != null) {
      return eventTextColorLight!;
    }
    if (brightness == Brightness.dark && eventTextColorDark != null) {
      return eventTextColorDark!;
    }
    if (eventTextColor != null) {
      return eventTextColor!;
    }
    
    return Colors.white;
  }

  Color getHoverColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && hoverColorLight != null) {
      return hoverColorLight!;
    }
    if (brightness == Brightness.dark && hoverColorDark != null) {
      return hoverColorDark!;
    }
    if (hoverColor != null) {
      return hoverColor!;
    }
    
    return brightness == Brightness.light
        ? Colors.grey.withOpacity(0.1)
        : Colors.white.withOpacity(0.05);
  }

  Color getTodayIndicatorTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && todayIndicatorTextColorLight != null) {
      return todayIndicatorTextColorLight!;
    }
    if (brightness == Brightness.dark && todayIndicatorTextColorDark != null) {
      return todayIndicatorTextColorDark!;
    }
    if (todayIndicatorTextColor != null) {
      return todayIndicatorTextColor!;
    }
    
    return Theme.of(context).colorScheme.surface;
  }

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
    );
  }

  @override
  ThemeExtension<JazmineCalendarTheme> lerp(
    ThemeExtension<JazmineCalendarTheme>? other,
    double t,
  ) {
    if (other is! JazmineCalendarTheme) {
      return this;
    }

    return JazmineCalendarTheme(
      seedColor: Color.lerp(seedColor, other.seedColor, t),
      gridLineColor: Color.lerp(gridLineColor, other.gridLineColor, t),
      gridLineColorLight: Color.lerp(gridLineColorLight, other.gridLineColorLight, t),
      gridLineColorDark: Color.lerp(gridLineColorDark, other.gridLineColorDark, t),
      selectedDayColor: Color.lerp(selectedDayColor, other.selectedDayColor, t),
      selectedDayColorLight: Color.lerp(selectedDayColorLight, other.selectedDayColorLight, t),
      selectedDayColorDark: Color.lerp(selectedDayColorDark, other.selectedDayColorDark, t),
      weekdayHeaderStyle: TextStyle.lerp(weekdayHeaderStyle, other.weekdayHeaderStyle, t),
      dateTextStyle: TextStyle.lerp(dateTextStyle, other.dateTextStyle, t),
      timeTextStyle: TextStyle.lerp(timeTextStyle, other.timeTextStyle, t),
      monthViewTheme: monthViewTheme,
      eventBackgroundColor: Color.lerp(eventBackgroundColor, other.eventBackgroundColor, t),
      eventBackgroundColorLight: Color.lerp(eventBackgroundColorLight, other.eventBackgroundColorLight, t),
      eventBackgroundColorDark: Color.lerp(eventBackgroundColorDark, other.eventBackgroundColorDark, t),
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t),
      hoverColorLight: Color.lerp(hoverColorLight, other.hoverColorLight, t),
      hoverColorDark: Color.lerp(hoverColorDark, other.hoverColorDark, t),
      todayIndicatorTextColor: Color.lerp(todayIndicatorTextColor, other.todayIndicatorTextColor, t),
      todayIndicatorTextColorLight: Color.lerp(todayIndicatorTextColorLight, other.todayIndicatorTextColorLight, t),
      todayIndicatorTextColorDark: Color.lerp(todayIndicatorTextColorDark, other.todayIndicatorTextColorDark, t),
    );
  }
}

// Example of view-specific theme
class MonthViewTheme {
  final TextStyle? trailingDaysTextStyle;
  final Color? trailingDaysColor;
  final Color? trailingDaysColorLight;
  final Color? trailingDaysColorDark;
  final Color? trailingDaysBackgroundColor;
  final Color? trailingDaysBackgroundColorLight;
  final Color? trailingDaysBackgroundColorDark;

  const MonthViewTheme({
    this.trailingDaysTextStyle,
    this.trailingDaysColor,
    this.trailingDaysColorLight,
    this.trailingDaysColorDark,
    this.trailingDaysBackgroundColor,
    this.trailingDaysBackgroundColorLight,
    this.trailingDaysBackgroundColorDark,
  });

  Color? getTrailingDaysBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && trailingDaysBackgroundColorLight != null) {
      return trailingDaysBackgroundColorLight;
    }
    if (brightness == Brightness.dark && trailingDaysBackgroundColorDark != null) {
      return trailingDaysBackgroundColorDark;
    }
    return trailingDaysBackgroundColor;
  }

  Color getTrailingDaysColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && trailingDaysColorLight != null) {
      return trailingDaysColorLight!;
    }
    if (brightness == Brightness.dark && trailingDaysColorDark != null) {
      return trailingDaysColorDark!;
    }
    if (trailingDaysColor != null) {
      return trailingDaysColor!;
    }
    
    return brightness == Brightness.light
        ? Colors.grey.withOpacity(0.5)
        : Colors.grey.withOpacity(0.6);
  }

  TextStyle getTrailingDaysTextStyle(BuildContext context) {
    return trailingDaysTextStyle ?? 
           Theme.of(context).textTheme.bodyMedium!.copyWith(
             color: getTrailingDaysColor(context),
           );
  }
}

class TimelineViewTheme {
  final Color timeAxisBackgroundColor;
  final Color timeAxisBackgroundColorDark;
  final double timeAxisWidth;

  const TimelineViewTheme({
    this.timeAxisBackgroundColor = const Color(0xFFF5F5F5),
    this.timeAxisBackgroundColorDark = const Color(0xFF424242),
    this.timeAxisWidth = 60.0,
  });
}

class AgendaViewTheme {
  final Color dateDividerColor;
  final Color dateDividerColorDark;
  final TextStyle dateHeaderStyle;

  const AgendaViewTheme({
    this.dateDividerColor = const Color(0x1A000000),
    this.dateDividerColorDark = const Color(0x1AFFFFFF),
    this.dateHeaderStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  });
}
