import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';

import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';

class MonthView extends BaseCalendarView {
  const MonthView({super.key});

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      startDate, DateTime selectedDate) {
    final calendarWidget = JazmineCalendar.of(context);
    final controller = calendarWidget.controller;
    final configuration = calendarWidget.monthConfiguration;
    const weekNumberWidth = 30.0;

    return Column(
      children: [
        _buildWeekdayHeader(context, configuration, weekNumberWidth),
        Expanded(
          child: _buildMonthGrid(
            startDate,
            controller,
            context,
            configuration,
            weekNumberWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(
    DateTime selectedDate,
    CalendarController controller,
    BuildContext context,
    MonthViewConfiguration configuration,
    weekNumberWidth,
  ) {
    // Use the calendar days mode from configuration to determine how many days to show
    final dates = DateHelper.calendarDaysForMonth(selectedDate,
        calendarDaysMode: configuration.calendarDaysMode);
    // Calculate the number of weeks between the first and last date
    final weeksCount = (dates.length / configuration.daysPerWeek).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CalendarGrid(
          dates: dates,
          controller: controller,
          headerDateFormat: DateFormat(
              '',
              CalendarLocalization.of(context)
                  .locale
                  .languageCode), // Empty since we handle date display in cellBuilder
          numberOfColumns: configuration.daysPerWeek,
          numberOfRows: weeksCount,
          slotDuration: const Duration(days: 1),
          intervalDuration: Duration.zero,
          orientation: Axis.vertical,
          rowHeaderWidth: weekNumberWidth, // week number header
          showCurrentTimeIndicator: false,
          gridLineWidth: configuration.gridLineWidth,
          headerBuilder: _buildWeekNumberHeader,
          cellBuilder: (context, date, index, orientation) {
            final isTrailingDay = date.month != selectedDate.month;
            final dayNumber = date.day;
            final col = index % configuration.daysPerWeek;
            final row = index ~/ configuration.daysPerWeek;

            if (isTrailingDay) {
              if (!configuration.showTrailingDays) {
                return Container();
              }

              // Determine if this is a trailing day that should have special formatting
              bool isSpecialTrailingDay = false;

              // For previous month trailing days (at the beginning)
              if (date.month < selectedDate.month ||
                  (date.month == 12 && selectedDate.month == 1)) {
                // Only the first day of the previous month that appears should have special formatting
                isSpecialTrailingDay = index == 0 || date.day == 1;
              }
              // For next month trailing days (at the end)
              else if (date.month > selectedDate.month ||
                  (date.month == 1 && selectedDate.month == 12)) {
                // Only the first day of the next month should have special formatting
                isSpecialTrailingDay = date.day == 1;
              }

              return _buildTrailingDayCell(
                date,
                context,
                controller,
                configuration,
                isFirstTrailingDay: isSpecialTrailingDay,
              );
            }

            return _buildDayCell(
              date,
              controller,
              context,
              configuration,
              isFirstDayOfMonth: dayNumber == 1,
              isLastColumn: col == configuration.daysPerWeek - 1,
              isLastRow: row == weeksCount - 1,
            );
          },
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime date,
    CalendarController controller,
    BuildContext context,
    MonthViewConfiguration configuration, {
    bool isFirstDayOfMonth = false,
    bool isLastColumn = false,
    bool isLastRow = false,
  }) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineColor = theme.brightness == Brightness.light
        ? calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.2)
        : calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.3);

    // Determine the appropriate format based on device size
    String formatString;
    if (UIHelper.isSmallDevice(context) && isFirstDayOfMonth) {
      // Small devices: Use more compact format for first day of month (e.g., "1/15" for January 15)
      formatString = 'M/d';
    } else if (isFirstDayOfMonth) {
      // Regular devices: Use the format from settings for first day of month
      formatString = configuration.firstDayOfMonthFormat;
    } else {
      // Regular day format for all devices
      formatString = configuration.monthDaysFormat;
    }

    return CalendarTimeSlot(
      date: date,
      controller: controller,
      showDate: configuration.showDateInCell,
      formatDate: DateFormat(
          formatString, CalendarLocalization.of(context).locale.languageCode),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
          bottom: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
        ),
      ),
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      padding: const EdgeInsets.all(1),
      dateAlignment: Alignment.topCenter,
      todayCircleSize: 32,
      datePadding: const EdgeInsets.only(top: 8),
    );
  }

  Widget _buildTrailingDayCell(
    DateTime date,
    BuildContext context,
    CalendarController controller,
    MonthViewConfiguration configuration, {
    bool isFirstTrailingDay = false,
  }) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final monthTheme = theme.extension<MonthViewTheme>();
    final gridLineColor = theme.brightness == Brightness.light
        ? calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.2)
        : calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.3);

    // Determine the appropriate format based on device size
    String formatString;
    if (UIHelper.isSmallDevice(context) && isFirstTrailingDay) {
      // Small devices: Use more compact format for first trailing day (e.g., "2/1" for February 1)
      formatString = 'M/d';
    } else if (isFirstTrailingDay) {
      // Regular devices: Use the format from settings for first trailing day
      formatString = configuration.firstTrailingDaysFormat;
    } else {
      // Regular day format for all devices
      formatString = configuration.monthDaysFormat;
    }

    return CalendarTimeSlot(
      date: date,
      controller: controller,
      showDate: configuration.showDateInCell,
      formatDate: DateFormat(
          formatString, CalendarLocalization.of(context).locale.languageCode),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
          bottom: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
        ),
        color: monthTheme?.getTrailingDaysBackgroundColor(context),
      ),
      padding: const EdgeInsets.all(2),
      dateAlignment: Alignment.topCenter,
      todayCircleSize: 32,
      datePadding: const EdgeInsets.only(top: 8),
    );
  }

  Widget _buildWeekdayHeader(
    BuildContext context,
    MonthViewConfiguration configuration,
    double weekNumberWidth,
  ) {
    final controller = JazmineCalendar.of(context).controller;
    final locale = CalendarLocalization.of(context).locale.languageCode;

    // Determine the appropriate weekday format based on device size
    String formatPattern;
    if (UIHelper.isSmallDevice(context)) {
      // Small devices: Show only first letter (e.g., "M" for Monday)
      formatPattern = 'EEEEE';
    } else if (UIHelper.isMediumDevice(context)) {
      // Medium devices: Show abbreviation (e.g., "Mon")
      formatPattern = 'E';
    } else {
      // Large devices: Use the format from settings
      formatPattern = configuration.weekdayFormat;
    }

    final weekdayFormat = DateFormat(formatPattern, locale);
    final now = DateTime.now();
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineColor = theme.brightness == Brightness.light
        ? calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.2)
        : calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        border: configuration.showWeekdayHeaderBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: gridLineColor,
                  width: configuration.gridLineWidth,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Add space for week number column
          SizedBox(width: weekNumberWidth),
          // Wrap weekday headers in Expanded to take remaining space
          Expanded(
            child: Row(
              children: List.generate(configuration.daysPerWeek, (index) {
                // Calculate weekday based on firstDayOfWeek
                final weekday = DateTime(
                  now.year,
                  now.month,
                  now.day - now.weekday + controller.firstDayOfWeek + index,
                );
                return Expanded(
                  child: Container(
                    padding: configuration.weekdayHeaderPadding,
                    alignment: configuration.weekdayHeaderAlignment,
                    child: Text(
                      weekdayFormat.format(weekday),
                      style: configuration.weekdayHeaderStyle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNumberHeader(
    BuildContext context,
    DateTime date,
    bool isVertical,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineColor = theme.brightness == Brightness.light
        ? calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.2)
        : calendarTheme?.getGridLineColor(context) ??
            Colors.grey.withOpacity(0.3);

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: gridLineColor,
            width:
                1.0, // Using a default width since we can't access configuration
          ),
        ),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${CalendarLocalization.of(context).weekLabel} ',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              '${date.weekNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
