// Base configuration that all view configurations extend from
import 'package:flutter/widgets.dart';

abstract class BaseViewConfiguration {
  final Alignment dateAlignment;
  final double gridLineWidth;

  const BaseViewConfiguration({
    this.dateAlignment = Alignment.center,
    this.gridLineWidth = 0.5,
  });
}

class DayViewConfiguration extends BaseViewConfiguration {
  final bool showCurrentTimeIndicator;
  final double hourHeight;
  final double timebarWidth;

  const DayViewConfiguration({
    super.dateAlignment,
    this.showCurrentTimeIndicator = true,
    this.hourHeight = 60,
    this.timebarWidth = 60,
  });
}

class WeekViewConfiguration extends DayViewConfiguration {
  final bool showWeekends;
  final String weekdayFormat;

  const WeekViewConfiguration({
    super.dateAlignment,
    super.showCurrentTimeIndicator,
    super.hourHeight,
    this.showWeekends = true,
    this.weekdayFormat = 'EEE',
  });
}

class TimelineConfiguration extends BaseViewConfiguration {
  /// The time interval between slots
  final Duration interval;

  /// Width of the resource header column
  final double resourceHeaderWidth;

  /// Height of the time header row
  final double timeHeaderHeight;

  /// Minimum width of each time slot
  final double minTimeSlotWidth;

  /// Whether to show the current time indicator
  final bool showCurrentTimeIndicator;

  const TimelineConfiguration({
    super.dateAlignment,
    this.interval = const Duration(minutes: 30),
    this.resourceHeaderWidth = 100.0,
    this.timeHeaderHeight = 50.0,
    this.minTimeSlotWidth = 60.0,
    this.showCurrentTimeIndicator = true,
  });
}

class AgendaViewConfiguration extends BaseViewConfiguration {
  final String dateFormat;
  final bool groupByDate;
  final EdgeInsets dateDividerPadding;

  const AgendaViewConfiguration({
    super.dateAlignment,
    this.dateFormat = 'EEEE, MMMM d',
    this.groupByDate = true,
    this.dateDividerPadding = const EdgeInsets.symmetric(vertical: 8),
  });
}

/// Defines how many days should be shown in the month view
enum CalendarDaysMode {
  /// Always show 6 weeks (42 days) regardless of the month
  fixed,

  /// Dynamically adjust the number of days based on the actual month
  /// Only show the days needed for the month plus trailing days to complete the week
  dynamic
}

class MonthViewConfiguration extends BaseViewConfiguration {
  final int daysPerWeek;
  final String weekdayFormat;
  final TextStyle weekdayHeaderStyle;
  final EdgeInsets weekdayHeaderPadding;
  final Alignment weekdayHeaderAlignment;
  final bool showDateInCell;
  final bool showTrailingDays;
  final double minCellHeight;
  final String firstTrailingDaysFormat;
  final String monthDaysFormat;
  final String firstDayOfMonthFormat;
  final bool showWeekdayHeaderBottomBorder;

  /// Controls how many days are shown in the month view
  /// When fixed, always shows 6 weeks (42 days)
  /// When dynamic, only shows the days needed for the month plus trailing days to complete the week
  final CalendarDaysMode calendarDaysMode;

  const MonthViewConfiguration({
    super.dateAlignment,
    this.daysPerWeek = 7,
    this.weekdayFormat = 'EEEE',
    this.weekdayHeaderStyle = const TextStyle(fontWeight: FontWeight.w500),
    this.weekdayHeaderPadding = const EdgeInsets.fromLTRB(8, 8, 8, 16),
    this.weekdayHeaderAlignment = Alignment.center,
    this.showDateInCell = true,
    this.showTrailingDays = true,
    this.minCellHeight = 100.0,
    this.firstTrailingDaysFormat = 'MMM d',
    this.monthDaysFormat = 'd',
    this.firstDayOfMonthFormat = 'MMM d',
    this.showWeekdayHeaderBottomBorder = true,
    this.calendarDaysMode = CalendarDaysMode.fixed,
  });
}
