import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../jazmine_calendar.dart';
import '../extensions/date_extensions.dart';
import 'base_calendar_view.dart';
import 'widgets/calendar_time_slot.dart';
import 'package:intl/intl.dart';

class MonthView extends BaseCalendarView {
  final MonthViewConfiguration configuration;

  const MonthView({
    super.key,
    this.configuration = const MonthViewConfiguration(),
  });

  Widget _buildWeekdayHeader() {
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
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        return ValueListenableBuilder<List<Event>>(
          valueListenable: controller.eventsNotifier,
          builder: (context, events, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final displayDate = controller.displayDate;

            return Column(
              children: [
                _buildWeekdayHeader(),
                Expanded(
                  child: _buildMonthGrid(
                    displayDate,
                    events,
                    controller,
                    context,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMonthGrid(
    DateTime selectedDate,
    List<Event> events,
    JazmineCalendarController controller,
    BuildContext context,
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
    BuildContext context, {
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
    JazmineCalendarController controller, {
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

/// Configuration class for non-theme related customization
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
  final Alignment dateAlignment;

  const MonthViewConfiguration({
    super.gridLineColor,
    super.gridLineColorDark,
    super.selectedDayColor,
    super.selectedDayColorDark,
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
    this.dateAlignment = Alignment.center,
  });
}
