import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';

import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';

class MonthView extends BaseCalendarView {
  const MonthView({super.key});

  @override
  Widget buildCalendarView(
      BuildContext context, DateTime startDate, DateTime selectedDate) {
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
    JazmineCalendarController controller,
    BuildContext context,
    MonthViewConfiguration configuration,
    weekNumberWidth,
  ) {
    final firstDay = selectedDate.firstDayOfMonth;
    final firstDayOfWeek = configuration.firstDayOfWeek;
    final startDate = firstDay.getWeekStartDate(firstDayOfWeek);
    //final lastDayOfMonth = selectedDate.lastDayOfMonth;

    final dateRange = CalendarViewService().monthViewDateRange(selectedDate);
    final weeksCount = startDate.weeksBetween(dateRange.last);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CalendarGrid(
          startDate: dateRange.first,
          endDate: dateRange.last,
          controller: controller,
          headerDateFormat: DateFormat(
              ''), // Empty since we handle date display in cellBuilder
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

              final isFirstTrailingDay = date.day == 1 || index == 0;
              return _buildTrailingDayCell(
                date,
                context,
                controller,
                configuration,
                isFirstTrailingDay: isFirstTrailingDay,
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
    JazmineCalendarController controller,
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

    return CalendarTimeSlot(
      date: date,
      controller: controller,
      showDate: configuration.showDateInCell,
      formatDate: DateFormat(isFirstDayOfMonth
          ? configuration.firstDayOfMonthFormat
          : configuration.monthDaysFormat),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
          bottom: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
        ),
      ),
      selectedDecoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      padding: const EdgeInsets.all(1),
      dateAlignment: configuration.dateAlignment,
      todayCircleSize: 32,
      datePadding: const EdgeInsets.only(top: 4),
    );
  }

  Widget _buildTrailingDayCell(
    DateTime date,
    BuildContext context,
    JazmineCalendarController controller,
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

    return CalendarTimeSlot(
      date: date,
      controller: controller,
      showDate: configuration.showDateInCell,
      formatDate: DateFormat(isFirstTrailingDay
          ? configuration.firstTrailingDaysFormat
          : configuration.monthDaysFormat),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
          bottom: BorderSide(
              color: gridLineColor, width: configuration.gridLineWidth),
        ),
        color: monthTheme?.getTrailingDaysBackgroundColor(context),
      ),
      selectedDecoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      dateAlignment: configuration.dateAlignment,
      todayCircleSize: 32,
      datePadding: const EdgeInsets.only(top: 4),
    );
  }

  Widget _buildWeekdayHeader(
    BuildContext context,
    MonthViewConfiguration configuration,
    double weekNumberWidth,
  ) {
    final weekdayFormat = DateFormat(configuration.weekdayFormat);
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
                  now.day - now.weekday + configuration.firstDayOfWeek + index,
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
              'Week ',
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
