import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/all_day_grid.dart';

class BaseDayView extends StatelessWidget {
  final List<DateTime> days;
  final double hourHeight;
  final bool showCurrentTimeIndicator;
  final DayViewConfiguration configuration;
  final Widget Function(BuildContext, DateTime, int, int)? slotBuilder;
  final Widget Function(BuildContext, DateTime)? headerBuilder;

  const BaseDayView({
    super.key,
    required this.days,
    required this.configuration,
    this.hourHeight = 60,
    this.showCurrentTimeIndicator = true,
    this.slotBuilder,
    this.headerBuilder,
  });

  void _scrollToCurrentTime(BuildContext context) {
    CalendarGrid.scrollToTime(context, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    final startTime = DateTime(days.first.year, days.first.month, days.first.day);
    final endTime = DateTime(days.first.year, days.first.month, days.first.day + 1);

    return ValueListenableBuilder<Duration>(
      valueListenable: controller.intervalNotifier,
      builder: (context, interval, _) {
        return Column(
          children: [
            _buildHeader(context, days),
            AllDayGrid(
              startDate: startTime,
              days: days,
              controller: controller,
              headerWidth: configuration.timebarWidth,
              borderColor: Colors.grey.withOpacity(0.2),
            ),
            Expanded(
              child: CalendarGrid(
                key: PageStorageKey('day_view_scroll'),
                startDate: startTime,
                endDate: endTime,
                controller: controller,
                headerDateFormat: DateFormat('HH:mm'),
                numberOfColumns: days.length,
                numberOfRows: const Duration(hours: 24).inMinutes ~/ interval.inMinutes,
                slotDuration: const Duration(days: 1),
                intervalDuration: interval,
                orientation: Axis.vertical,
                headerWidth: configuration.timebarWidth,
                headerBuilder: _buildTimebarHeader,

              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<DateTime> days) {
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
                                DateFormat('E d').format(date),
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
    
    // Format the time based on whether it's on the hour
    final String timeText;
    if (time.minute == 0) {
      if (is24HourFormat) {
        timeText = DateFormat('HH').format(time);
      } else {
        timeText = DateFormat('h a').format(time);
      }
    } else {
      timeText = ':${time.minute.toString().padLeft(2, '0')}';
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
            color: calendarTheme?.getGridLineColor(context) 
                ?? Colors.grey.withOpacity(0.2),
          ),
          right: BorderSide(
            color: calendarTheme?.getGridLineColor(context) 
                ?? Colors.grey.withOpacity(0.2),
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
