import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart'; // Restore BaseCalendarView import
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';
import 'package:jazmine_calendar/src/views/widgets/all_day_grid.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart'; // Keep for controller access if needed

class BaseDayView extends BaseCalendarView { // Revert to extending BaseCalendarView
  final List<DateTime> dates;
  final double hourHeight;
  final bool showCurrentTimeIndicator;
  final DayViewConfiguration configuration;
  final Widget Function(BuildContext, DateTime, int, int)? slotBuilder;
  final Widget Function(BuildContext, DateTime)? headerBuilder;
  final void Function(DateTime startTime)? onTimeSlotCreateInteraction;

  const BaseDayView({
    super.key,
    required this.dates,
    required this.configuration,
    this.hourHeight = 60,
    this.showCurrentTimeIndicator = true,
    this.slotBuilder,
    this.headerBuilder,
    this.onTimeSlotCreateInteraction,
  });

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller, // Restore buildCalendar
      startDate, DateTime selectedDate) {
    final uniqueDays = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList();

    return ValueListenableBuilder<Duration>(
      valueListenable: controller.intervalNotifier,
      builder: (context, interval, _) {
        // Restore original Column structure without the overlay Stack
        return Column(
          children: [
            _buildDateHeader(context, uniqueDays),
            AllDayGrid(
              dates: uniqueDays,
              controller: controller,
              headerWidth: configuration.timebarWidth,
              borderColor: Colors.grey.withOpacity(0.2),
            ),
            Expanded( // Restore Expanded
              // Restore original structure (CalendarGrid handles its internal Stack)
              child: CalendarGrid(
                key: const PageStorageKey('day_view_scroll'), // Restore key if needed
                // eventLayoutSurfaceKey: null, // Remove key passing
                dates: dates, // Use original dates list
                controller: controller,
                headerDateFormat: DateFormat('HH:mm'),
                numberOfColumns: uniqueDays.length,
                numberOfRows: const Duration(hours: 24).inMinutes ~/
                    interval.inMinutes,
                slotDuration: const Duration(days: 1),
                intervalDuration: interval,
                orientation: Axis.vertical,
                rowHeaderWidth: configuration.timebarWidth,
                headerBuilder: _buildTimebarHeader,
                showEvents: true,
                onTimeSlotCreateInteraction: onTimeSlotCreateInteraction,
                // drawDraggedEventInSurface parameter removed from CalendarGrid
              ),
            ),
          ],
        );
      },
    );
  }

  // Keep helper methods, ensure they access properties via `this.` or directly if stateless
  Widget _buildDateHeader(BuildContext context, List<DateTime> days) {
    return Container(
      height: 50, // Use fixed height or configuration value
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: configuration.timebarWidth),
          Expanded(
            child: Row(
              children: days
                  .map((date) => Expanded(
                        child: headerBuilder?.call(context, date) ??
                            Align(
                              alignment: configuration.dateAlignment,
                              child: Text(
                                // Combine short day name and day number
                                '${DateFormat.E(CalendarLocalization.of(context).locale.languageCode).format(date)} ${DateFormat.d(CalendarLocalization.of(context).locale.languageCode).format(date)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimebarHeader(
    BuildContext context,
    DateTime time,
    bool isVertical,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final localization = CalendarLocalization.of(context);

    final String timeText;
    final localTime = time.toLocal();

    if (localTime.minute == 0) {
      if (is24HourFormat) {
        timeText = DateFormat('HH', localization.locale.languageCode)
            .format(localTime);
      } else {
        timeText = DateFormat('h a', localization.locale.languageCode)
            .format(localTime);
      }
    } else {
      timeText = ':${localTime.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey[50]
            : theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.2),
          ),
          right: BorderSide(
            color: calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.only(right: 8),
      alignment: Alignment.topRight,
      child: Text(
        timeText,
        style: calendarTheme?.getTimeTextStyle(context) ??
            theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
      ),
    );
  }
}
