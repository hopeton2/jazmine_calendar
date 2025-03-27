import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/utils/typedefs.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class TimelineView extends StatefulWidget {
  final CalendarHeaderBuilder? headerBuilder;
  final TimelineConfiguration configuration;

  const TimelineView({
    super.key,
    this.headerBuilder,
    required this.configuration,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  @override
  Widget build(BuildContext context) {
    final calendarWidget = JazmineCalendar.of(context);
    final controller = calendarWidget.controller!;
    final configuration = calendarWidget.timelineConfiguration;

    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.displayDateNotifier,
      builder: (context, displayDate, _) {
        final startTime = DateTime(
          displayDate.year,
          displayDate.month,
          displayDate.day,
        );
        final endTime = startTime.add(const Duration(days: 1));

        return ValueListenableBuilder<Duration>(
          valueListenable: controller.intervalNotifier,
          builder: (context, interval, _) {
            return Column(
              children: [
                _buildTimeZoneHeader(controller.visibleTimeZones),
                Expanded(
                  child: CalendarGrid(
                    startDate: startTime,
                    endDate: endTime,
                    controller: controller,
                    headerDateFormat: DateFormat('HH:mm'),
                    numberOfColumns: const Duration(hours: 24).inMinutes ~/
                        interval.inMinutes,
                    numberOfRows: controller.visibleTimeZones.length,
                    slotDuration: interval,
                    intervalDuration: interval,
                    orientation: Axis.horizontal,
                    rowHeaderWidth: configuration.timeAxisWidth,
                    headerBuilder: _buildTimeHeader,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeZoneHeader(List<String> timeZones) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60), // Space for time axis
          ...timeZones.map((timeZone) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  timeZone,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeHeader(
    BuildContext context,
    DateTime time,
    bool isVertical,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    final is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    final String timeText;
    if (time.minute == 0) {
      timeText = is24HourFormat
          ? DateFormat('HH').format(time)
          : DateFormat('h a').format(time);
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
          right: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        timeText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}
