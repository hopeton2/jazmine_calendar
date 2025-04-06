import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';
import 'package:jazmine_calendar/src/views/widgets/all_day_grid.dart';

class BaseDayView extends BaseCalendarView {
  final List<DateTime> dates;
  final double hourHeight;
  final bool showCurrentTimeIndicator;
  final DayViewConfiguration configuration;
  final Widget Function(BuildContext, DateTime, int, int)? slotBuilder;
  final Widget Function(BuildContext, DateTime)? headerBuilder;
  final void Function(DateTime startTime)? onTimeSlotCreateInteraction; // Add callback

  const BaseDayView({
    super.key,
    required this.dates,
    required this.configuration,
    this.hourHeight = 60,
    this.showCurrentTimeIndicator = true,
    this.slotBuilder,
    this.headerBuilder,
    this.onTimeSlotCreateInteraction, // Add to constructor
  });

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      startDate, DateTime selectedDate) {
    final uniqueDays = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList();

    return ValueListenableBuilder<Duration>(
      valueListenable: controller.intervalNotifier,
      builder: (context, interval, _) {
        return Column(
          children: [
            _buildDateHeader(context, uniqueDays),
            AllDayGrid(
              dates: uniqueDays,
              controller: controller,
              headerWidth: configuration.timebarWidth,
              borderColor: Colors.grey.withOpacity(0.2),
            ),
            Expanded(
              child: Stack( // Restore inner Stack
                children: [
                  CalendarGrid(
                    key: const PageStorageKey('day_view_scroll'), // Restore key
                    dates: dates,
                    controller: controller,
                    headerDateFormat: DateFormat('HH:mm'),
                    numberOfColumns: uniqueDays.length,
                    numberOfRows: const Duration(hours: 24).inMinutes ~/
                        interval.inMinutes,
                    slotDuration: const Duration(days: 1),
                    intervalDuration: interval,
                    orientation: Axis.vertical,
                    rowHeaderWidth: configuration.timebarWidth,
                    // Use default columnHeaderHeight from CalendarGrid
                    headerBuilder: _buildTimebarHeader,
                    showEvents: true, // Re-enable events in CalendarGrid
                    onTimeSlotCreateInteraction: onTimeSlotCreateInteraction, // Pass callback
                  ),
                  // EventLayoutSurface will be re-added inside CalendarGrid
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, List<DateTime> days) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Add spacer with same width as timebar
          SizedBox(width: configuration.timebarWidth),
          // Wrap the Expanded widgets in a new Expanded to take remaining space
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

    // Format the time based on whether it's on the hour
    final String timeText;
    final localTime = time.toLocal(); // Convert UTC time to local

    if (localTime.minute == 0) {
      if (is24HourFormat) {
        // 24-hour format
        timeText = DateFormat('HH', localization.locale.languageCode)
            .format(localTime);
      } else {
        // 12-hour format with AM/PM
        timeText = DateFormat('h a', localization.locale.languageCode)
            .format(localTime);
      }
    } else {
      // Just show minutes for non-hour marks
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
