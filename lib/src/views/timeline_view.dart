import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/views/base_timeline_view.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

/// A timeline view that displays events horizontally with time on the top.
///
/// This view shows a horizontal timeline with time displayed at the top.
class TimelineView extends BaseTimelineView {
  // Use a default date that can be overridden at runtime
  TimelineView({super.key})
      : super(
          date: DateTime.now(),
          configuration: const TimelineConfiguration(),
        );

  @override
  TimelineConfiguration getConfiguration(BuildContext context) {
    return JazmineCalendar.of(context).timelineConfiguration;
  }
}
