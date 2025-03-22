// Base configuration that all view configurations extend from
import 'package:flutter/widgets.dart';

abstract class BaseViewConfiguration {
  final Color? gridLineColor;
  final Color? gridLineColorDark;
  final Color? selectedDayColor;
  final Color? selectedDayColorDark;
  final Alignment dateAlignment;

  const BaseViewConfiguration({
    this.gridLineColor,
    this.gridLineColorDark,
    this.selectedDayColor,
    this.selectedDayColorDark,
    this.dateAlignment = Alignment.center,
  });
}

class DayViewConfiguration extends BaseViewConfiguration {
  final Duration interval;
  final bool showCurrentTimeIndicator;
  final double hourHeight;

  const DayViewConfiguration({
    super.gridLineColor,
    super.selectedDayColor,
    super.dateAlignment,
    this.interval = const Duration(minutes: 30),
    this.showCurrentTimeIndicator = true,
    this.hourHeight = 60,
  });
}

class WeekViewConfiguration extends DayViewConfiguration {
  final bool showWeekends;
  final String weekdayFormat;

  const WeekViewConfiguration({
    super.gridLineColor,
    super.selectedDayColor,
    super.interval,
    super.showCurrentTimeIndicator,
    super.hourHeight,
    this.showWeekends = true,
    this.weekdayFormat = 'EEE',
  });
}

class TimelineViewConfiguration extends BaseViewConfiguration {
  final Duration interval;
  final double timeAxisWidth;
  final bool showCurrentTimeIndicator;

  const TimelineViewConfiguration({
    super.gridLineColor,
    super.selectedDayColor,
    this.interval = const Duration(minutes: 30),
    this.timeAxisWidth = 60.0,
    this.showCurrentTimeIndicator = true,
  });
}

class AgendaViewConfiguration extends BaseViewConfiguration {
  final String dateFormat;
  final bool groupByDate;
  final EdgeInsets dateDividerPadding;

  const AgendaViewConfiguration({
    super.gridLineColor,
    super.selectedDayColor,
    super.dateAlignment,
    this.dateFormat = 'EEEE, MMMM d',
    this.groupByDate = true,
    this.dateDividerPadding = const EdgeInsets.symmetric(vertical: 8),
  });
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

  const MonthViewConfiguration({
    super.gridLineColor,
    super.gridLineColorDark,
    super.selectedDayColor,
    super.selectedDayColorDark,
    super.dateAlignment,
    this.daysPerWeek = 7,
    this.weekdayFormat = 'E',
    this.weekdayHeaderStyle = const TextStyle(fontWeight: FontWeight.w500),
    this.weekdayHeaderPadding = const EdgeInsets.symmetric(vertical: 8),
    this.weekdayHeaderAlignment = Alignment.center,
    this.showDateInCell = true,
    this.showTrailingDays = true,
    this.minCellHeight = 100.0,
    this.firstTrailingDaysFormat = 'MMM d',
    this.monthDaysFormat = 'd',
    this.firstDayOfMonthFormat = 'MMM d',
  });
}
