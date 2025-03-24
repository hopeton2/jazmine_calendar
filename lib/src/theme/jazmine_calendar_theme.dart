import 'package:flutter/material.dart';

// Base calendar theme for colors
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
  final DayViewTheme dayViewTheme;
  final WeekViewTheme weekViewTheme;
  final AgendaViewTheme agendaViewTheme;

  final Color? hoverColor;
  final Color? hoverColorLight;
  final Color? hoverColorDark;

  final Color? todayIndicatorTextColor;
  final Color? todayIndicatorTextColorLight;
  final Color? todayIndicatorTextColorDark;

  final Color? allDayBackgroundColor;
  final Color? allDayBackgroundColorLight;
  final Color? allDayBackgroundColorDark;

  final TextStyle? eventTitleStyle;
  final TextStyle? eventTimeStyle;

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
    this.dayViewTheme = const DayViewTheme(),
    this.weekViewTheme = const WeekViewTheme(),
    this.agendaViewTheme = const AgendaViewTheme(),
    this.hoverColor,
    this.hoverColorLight,
    this.hoverColorDark,
    this.todayIndicatorTextColor,
    this.todayIndicatorTextColorLight,
    this.todayIndicatorTextColorDark,
    this.allDayBackgroundColor,
    this.allDayBackgroundColorLight,
    this.allDayBackgroundColorDark,
    this.eventTitleStyle,
    this.eventTimeStyle,
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
        ? Colors.grey.withOpacity(0.1)
        : Colors.grey.withOpacity(0.2);
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

  Color getSlotBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.surface;  // default, can be overridden
  }

  Color getAllDayBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.light && allDayBackgroundColorLight != null) {
      return allDayBackgroundColorLight!;
    }
    if (brightness == Brightness.dark && allDayBackgroundColorDark != null) {
      return allDayBackgroundColorDark!;
    }
    if (allDayBackgroundColor != null) {
      return allDayBackgroundColor!;
    }
    
    final baseColor = getSlotBackgroundColor(context);
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    return hslColor
        .withLightness((hslColor.lightness * 0.85).clamp(0.0, 1.0))
        .toColor();
  }

  TextStyle getEventTitleStyle(BuildContext context) {
    return eventTitleStyle ?? TextStyle(
      color: getEventTextColor(context),
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle getEventTimeStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return eventTimeStyle ?? TextStyle(
      color: getEventTextColor(context),
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
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
    Color? allDayBackgroundColor,
    Color? allDayBackgroundColorLight,
    Color? allDayBackgroundColorDark,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
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
      allDayBackgroundColor: Color.lerp(allDayBackgroundColor, other.allDayBackgroundColor, t),
      allDayBackgroundColorLight: Color.lerp(allDayBackgroundColorLight, other.allDayBackgroundColorLight, t),
      allDayBackgroundColorDark: Color.lerp(allDayBackgroundColorDark, other.allDayBackgroundColorDark, t),
      eventTitleStyle: TextStyle.lerp(eventTitleStyle, other.eventTitleStyle, t),
      eventTimeStyle: TextStyle.lerp(eventTimeStyle, other.eventTimeStyle, t),
    );
  }
}

class MonthViewTheme extends ThemeExtension<MonthViewTheme> {
  final TextStyle? weekdayHeaderStyle;
  final TextStyle? cellDateStyle;
  final TextStyle? trailingDatesStyle;
  final TextStyle? eventTitleStyle;
  final TextStyle? moreEventsStyle;
  final Color? trailingDaysColor;
  final Color? trailingDaysColorDark;

  const MonthViewTheme({
    this.weekdayHeaderStyle,
    this.cellDateStyle,
    this.trailingDatesStyle,
    this.eventTitleStyle,
    this.moreEventsStyle,
    this.trailingDaysColor,
    this.trailingDaysColorDark,
  });

  Color getTrailingDaysBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.dark && trailingDaysColorDark != null) {
      return trailingDaysColorDark!;
    }
    if (trailingDaysColor != null) {
      return trailingDaysColor!;
    }
    
    return brightness == Brightness.light
        ? Colors.grey.withOpacity(0.1)
        : Colors.grey.withOpacity(0.15);
  }

  @override
  MonthViewTheme copyWith({
    TextStyle? weekdayHeaderStyle,
    TextStyle? cellDateStyle,
    TextStyle? trailingDatesStyle,
    TextStyle? eventTitleStyle,
    TextStyle? moreEventsStyle,
    Color? trailingDaysColor,
    Color? trailingDaysColorDark,
  }) {
    return MonthViewTheme(
      weekdayHeaderStyle: weekdayHeaderStyle ?? this.weekdayHeaderStyle,
      cellDateStyle: cellDateStyle ?? this.cellDateStyle,
      trailingDatesStyle: trailingDatesStyle ?? this.trailingDatesStyle,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      moreEventsStyle: moreEventsStyle ?? this.moreEventsStyle,
      trailingDaysColor: trailingDaysColor ?? this.trailingDaysColor,
      trailingDaysColorDark: trailingDaysColorDark ?? this.trailingDaysColorDark,
    );
  }

  @override
  MonthViewTheme lerp(ThemeExtension<MonthViewTheme>? other, double t) {
    if (other is! MonthViewTheme) return this;
    return MonthViewTheme(
      weekdayHeaderStyle: TextStyle.lerp(weekdayHeaderStyle, other.weekdayHeaderStyle, t),
      cellDateStyle: TextStyle.lerp(cellDateStyle, other.cellDateStyle, t),
      trailingDatesStyle: TextStyle.lerp(trailingDatesStyle, other.trailingDatesStyle, t),
      eventTitleStyle: TextStyle.lerp(eventTitleStyle, other.eventTitleStyle, t),
      moreEventsStyle: TextStyle.lerp(moreEventsStyle, other.moreEventsStyle, t),
      trailingDaysColor: Color.lerp(trailingDaysColor, other.trailingDaysColor, t),
      trailingDaysColorDark: Color.lerp(trailingDaysColorDark, other.trailingDaysColorDark, t),
    );
  }
}

class DayViewTheme extends ThemeExtension<DayViewTheme> {
  final TextStyle? dateHeaderStyle;
  final TextStyle? timebarLabelStyle;
  final TextStyle? eventTitleStyle;
  final TextStyle? eventTimeStyle;
  final TextStyle? allDayEventStyle;

  const DayViewTheme({
    this.dateHeaderStyle,
    this.timebarLabelStyle,
    this.eventTitleStyle,
    this.eventTimeStyle,
    this.allDayEventStyle,
  });

  @override
  DayViewTheme copyWith({
    TextStyle? dateHeaderStyle,
    TextStyle? timebarLabelStyle,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
    TextStyle? allDayEventStyle,
  }) {
    return DayViewTheme(
      dateHeaderStyle: dateHeaderStyle ?? this.dateHeaderStyle,
      timebarLabelStyle: timebarLabelStyle ?? this.timebarLabelStyle,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      eventTimeStyle: eventTimeStyle ?? this.eventTimeStyle,
      allDayEventStyle: allDayEventStyle ?? this.allDayEventStyle,
    );
  }

  @override
  DayViewTheme lerp(ThemeExtension<DayViewTheme>? other, double t) {
    if (other is! DayViewTheme) return this;
    return DayViewTheme(
      dateHeaderStyle: TextStyle.lerp(dateHeaderStyle, other.dateHeaderStyle, t),
      timebarLabelStyle: TextStyle.lerp(timebarLabelStyle, other.timebarLabelStyle, t),
      eventTitleStyle: TextStyle.lerp(eventTitleStyle, other.eventTitleStyle, t),
      eventTimeStyle: TextStyle.lerp(eventTimeStyle, other.eventTimeStyle, t),
      allDayEventStyle: TextStyle.lerp(allDayEventStyle, other.allDayEventStyle, t),
    );
  }
}

class WeekViewTheme extends ThemeExtension<WeekViewTheme> {
  final TextStyle? weekdayHeaderStyle;
  final TextStyle? dateStyle;
  final TextStyle? timebarLabelStyle;
  final TextStyle? eventTitleStyle;
  final TextStyle? eventTimeStyle;

  const WeekViewTheme({
    this.weekdayHeaderStyle,
    this.dateStyle,
    this.timebarLabelStyle,
    this.eventTitleStyle,
    this.eventTimeStyle,
  });

  @override
  WeekViewTheme copyWith({
    TextStyle? weekdayHeaderStyle,
    TextStyle? dateStyle,
    TextStyle? timebarLabelStyle,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
  }) {
    return WeekViewTheme(
      weekdayHeaderStyle: weekdayHeaderStyle ?? this.weekdayHeaderStyle,
      dateStyle: dateStyle ?? this.dateStyle,
      timebarLabelStyle: timebarLabelStyle ?? this.timebarLabelStyle,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      eventTimeStyle: eventTimeStyle ?? this.eventTimeStyle,
    );
  }

  @override
  WeekViewTheme lerp(ThemeExtension<WeekViewTheme>? other, double t) {
    if (other is! WeekViewTheme) return this;
    return WeekViewTheme(
      weekdayHeaderStyle: TextStyle.lerp(weekdayHeaderStyle, other.weekdayHeaderStyle, t),
      dateStyle: TextStyle.lerp(dateStyle, other.dateStyle, t),
      timebarLabelStyle: TextStyle.lerp(timebarLabelStyle, other.timebarLabelStyle, t),
      eventTitleStyle: TextStyle.lerp(eventTitleStyle, other.eventTitleStyle, t),
      eventTimeStyle: TextStyle.lerp(eventTimeStyle, other.eventTimeStyle, t),
    );
  }
}

class AgendaViewTheme extends ThemeExtension<AgendaViewTheme> {
  final TextStyle? dateHeaderStyle;
  final TextStyle? eventTitleStyle;
  final TextStyle? eventTimeStyle;
  final TextStyle? sectionHeaderStyle;

  const AgendaViewTheme({
    this.dateHeaderStyle,
    this.eventTitleStyle,
    this.eventTimeStyle,
    this.sectionHeaderStyle,
  });

  @override
  AgendaViewTheme copyWith({
    TextStyle? dateHeaderStyle,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
    TextStyle? sectionHeaderStyle,
  }) {
    return AgendaViewTheme(
      dateHeaderStyle: dateHeaderStyle ?? this.dateHeaderStyle,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      eventTimeStyle: eventTimeStyle ?? this.eventTimeStyle,
      sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
    );
  }

  @override
  AgendaViewTheme lerp(ThemeExtension<AgendaViewTheme>? other, double t) {
    if (other is! AgendaViewTheme) return this;
    return AgendaViewTheme(
      dateHeaderStyle: TextStyle.lerp(dateHeaderStyle, other.dateHeaderStyle, t),
      eventTitleStyle: TextStyle.lerp(eventTitleStyle, other.eventTitleStyle, t),
      eventTimeStyle: TextStyle.lerp(eventTimeStyle, other.eventTimeStyle, t),
      sectionHeaderStyle: TextStyle.lerp(sectionHeaderStyle, other.sectionHeaderStyle, t),
    );
  }
}
