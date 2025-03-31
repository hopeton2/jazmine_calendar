import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';

/// Base class for timeline views that display events horizontally with time on the top.
/// 
/// This class provides the foundation for creating timeline views where time is displayed
/// horizontally across the top, and rows represent different resources.
class BaseTimelineView extends BaseCalendarView {
  /// Creates a base timeline view.
  
  final List<DateTime> dates;
  final double hourWidth;
  final bool showCurrentTimeIndicator;
  final DayViewConfiguration configuration;
  final Widget Function(BuildContext, DateTime, int, int)? slotBuilder;
  final Widget Function(BuildContext, DateTime)? headerBuilder;
  
  const BaseTimelineView({
    super.key,
    required this.dates,
    required this.configuration,
    this.hourWidth = 100,
    this.showCurrentTimeIndicator = true,
    this.slotBuilder,
    this.headerBuilder,
  });

  /// Builds the time header for each time slot.
  Widget buildTimebarHeader(
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
    } else if (time.minute % 30 == 0) {
      timeText = ':${time.minute.toString().padLeft(2, '0')}';
    } else {
      timeText = '';
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
            color: calendarTheme?.getGridLineColor(context) ?? 
                Colors.grey.withOpacity(0.2),
          ),
          bottom: BorderSide(
            color: calendarTheme?.getGridLineColor(context) ?? 
                Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        timeText,
        style: calendarTheme?.getTimeTextStyle(context) ??
            theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
      ),
    );
  }

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      DateTime startDate, DateTime selectedDate) {

    // Use ValueListenableBuilder to listen for interval changes
    return ValueListenableBuilder<Duration>(
      valueListenable: controller.intervalNotifier,
      builder: (context, interval, _) {
   
        // Let CalendarGrid handle scrolling internally
        return CalendarGrid(
          key: const PageStorageKey('timeline_view_scroll'),
          dates: dates,
          controller: controller,
          headerDateFormat: DateFormat('HH:mm'),
          numberOfColumns: dates.length,
          numberOfRows: 1, // Just one row for now
          slotDuration: interval,
          intervalDuration: interval,
          orientation: Axis.horizontal,
          rowHeaderWidth: 0, // No row header for now
          headerBuilder: buildTimebarHeader,
          showCurrentTimeIndicator: showCurrentTimeIndicator,
        );
      },
    );
  }
}
