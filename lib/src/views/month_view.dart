import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/models/event.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';


class MonthView extends StatelessWidget {
  const MonthView({super.key});

  Widget _buildWeekdayHeader(BuildContext context, MonthViewConfiguration configuration) {
    final weekdayFormat = DateFormat(configuration.weekdayFormat);
    final now = DateTime.now();
    return Row(
      children: List.generate(configuration.daysPerWeek, (index) {
        final weekday =
            DateTime(now.year, now.month, now.day - now.weekday + index);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarWidget = JazmineCalendar.of(context);
    final controller = calendarWidget.controller!;
    final configuration = calendarWidget.monthConfiguration;
    
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.displayDateNotifier,
      builder: (context, displayDate, _) {
        return Column(
          children: [
            _buildWeekdayHeader(context, configuration),
            Expanded(
              child: FutureBuilder<List<Event>>(
                future: controller.getAllEvents(),
                builder: (context, snapshot) {
                  final events = snapshot.data ?? [];
                  return _buildMonthGrid(
                    displayDate,
                    events,  // Pass events list as second parameter
                    controller,
                    context,
                    configuration,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthGrid(
    DateTime selectedDate,
    List<Event> events,
    JazmineCalendarController controller,
    BuildContext context,
    MonthViewConfiguration configuration,
  ) {
    final firstDay = selectedDate.firstDayOfMonth;
    final daysInMonth = selectedDate.getDaysInMonth();
    final firstWeekday = firstDay.weekday;
    final weeksCount =
        ((daysInMonth.length + firstWeekday - 1) / configuration.daysPerWeek)
            .ceil();

    final allDayEvents = events.where((event) => event.isAllDay).toList();
    final regularEvents = events.where((event) => !event.isAllDay).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final calendarTheme = theme.extension<JazmineCalendarTheme>();
        final borderColor = theme.brightness == Brightness.light
            ? configuration.gridLineColor ??
                calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.2)
            : configuration.gridLineColorDark ??
                calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.3);

        final availableHeight = constraints.maxHeight;
        final calculatedCellHeight = availableHeight / weeksCount;
        final ScrollPhysics physics =
            calculatedCellHeight < configuration.minCellHeight
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics();
        final cellHeight =
            max(calculatedCellHeight, configuration.minCellHeight);

        return Container(
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: 0.5),
              left: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: configuration.daysPerWeek,
              childAspectRatio: constraints.maxWidth /
                  (configuration.daysPerWeek * cellHeight),
              mainAxisExtent: cellHeight,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            physics: physics,
            itemCount: weeksCount * configuration.daysPerWeek,
            itemBuilder: (context, index) {
              final row = index ~/ configuration.daysPerWeek;
              final col = index % configuration.daysPerWeek;
              final dayNumber = index - firstWeekday + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth.length) {
                if (!configuration.showTrailingDays) {
                  return Container();
                }

                final date = dayNumber < 1
                    ? firstDay.subtract(Duration(days: -dayNumber + 1))
                    : firstDay.add(Duration(days: dayNumber - 1));

                final bool isFirstTrailingDay = dayNumber < 1
                    ? index == 0
                    : dayNumber == daysInMonth.length + 1;

                return _buildTrailingDayCell(
                  date,
                  context,
                  controller,
                  configuration,
                  isFirstTrailingDay: isFirstTrailingDay,
                );
              }

              final date =
                  DateTime(selectedDate.year, selectedDate.month, dayNumber);

              final dayEvents = regularEvents
                  .where((event) => date.isEventInDay(event.start, event.end))
                  .toList();

              final dayAllDayEvents = allDayEvents
                  .where((event) => date.isEventInDay(event.start, event.end))
                  .toList();

              return _buildDayCell(
                date,
                dayEvents,
                dayAllDayEvents,
                controller,
                context,
                configuration,
                isFirstDayOfMonth: dayNumber == 1,
                isLastColumn: col == configuration.daysPerWeek - 1,
                isLastRow: row == weeksCount - 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime date, 
    List<Event> events,
    List<Event> allDayEvents,
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
        ? configuration.gridLineColor ?? calendarTheme?.getGridLineColor(context) ?? Colors.grey.withOpacity(0.2)
        : configuration.gridLineColorDark ?? calendarTheme?.getGridLineColor(context) ?? Colors.grey.withOpacity(0.3);

    return CalendarTimeSlot(
      date: date, 
      events: events, 
      allDayEvents: allDayEvents, 
      controller: controller, 
      showDate: configuration.showDateInCell,
      isFirstDayOfEvent: (event) => event.start.isSameDay(date), 
      isLastDayOfEvent: (event) => event.end.isSameDay(date),
      formatDate: DateFormat(isFirstDayOfMonth ? configuration.firstDayOfMonthFormat : configuration.monthDaysFormat),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: gridLineColor, width: 0.5),
          bottom: BorderSide(color: gridLineColor, width: 0.5),
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
        ? configuration.gridLineColor ?? calendarTheme?.getGridLineColor(context) ?? Colors.grey.withOpacity(0.2)
        : configuration.gridLineColorDark ?? calendarTheme?.getGridLineColor(context) ?? Colors.grey.withOpacity(0.3);

    return CalendarTimeSlot(
      date: date, 
      events: const [], 
      allDayEvents: const [], 
      controller: controller, 
      showDate: configuration.showDateInCell,
      isFirstDayOfEvent: (event) => event.start.isSameDay(date), 
      isLastDayOfEvent: (event) => event.end.isSameDay(date),
      formatDate: DateFormat(isFirstTrailingDay ? configuration.firstTrailingDaysFormat : configuration.monthDaysFormat),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: gridLineColor, width: 0.5),
          bottom: BorderSide(color: gridLineColor, width: 0.5),
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
}
