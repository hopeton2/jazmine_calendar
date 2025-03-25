import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';

class IntervalService {
  // Singleton instance
  static final IntervalService _instance = IntervalService._internal();

  // Factory constructor to return the same instance
  factory IntervalService() {
    return _instance;
  }

  // Private constructor
  IntervalService._internal();

  DateTime getNextDate(DateTime date, TimelineInterval interval) {
    return switch (interval) {
      TimelineInterval.week => date.add(const Duration(days: 7)),
      TimelineInterval.month =>
        date.firstDayOfMonth.add(const Duration(days: 32)).firstDayOfMonth,
      TimelineInterval.quarter => date.nextQuarter,
      TimelineInterval.year => date.nextYear,
      _ when interval.duration != null => date.add(interval.duration!),
      _ => throw ArgumentError('Invalid interval type'),
    };
  }

  DateTime getPreviousDate(DateTime date, TimelineInterval interval) {
    return switch (interval) {
      TimelineInterval.week => date.subtract(const Duration(days: 7)),
      TimelineInterval.month =>
        date.firstDayOfMonth.subtract(const Duration(days: 1)).firstDayOfMonth,
      TimelineInterval.quarter => date.previousQuarter,
      TimelineInterval.year => date.previousYear,
      _ when interval.duration != null => date.subtract(interval.duration!),
      _ => throw ArgumentError('Invalid interval type'),
    };
  }

  Duration getDurationBetween(
      DateTime start, DateTime end, TimelineInterval interval) {
    return switch (interval) {
      TimelineInterval.week => const Duration(days: 7),
      TimelineInterval.month =>
        start.firstDayOfMonth.durationUntil(start.lastDayOfMonth),
      TimelineInterval.quarter =>
        start.firstDayOfQuarter.durationUntil(start.lastDayOfQuarter),
      TimelineInterval.year =>
        start.firstDayOfYear.durationUntil(start.lastDayOfYear),
      _ when interval.duration != null => interval.duration!,
      _ => throw ArgumentError('Invalid interval type'),
    };
  }

  DateTime snapToInterval(DateTime date, TimelineInterval interval) {
    return switch (interval) {
      TimelineInterval.week => date.getWeekStartDateOfDay(false),
      TimelineInterval.month => date.firstDayOfMonth,
      TimelineInterval.quarter => date.firstDayOfQuarter,
      TimelineInterval.year => date.firstDayOfYear,
      _ when interval.duration != null =>
        _snapToTimeDuration(date, interval.duration!),
      _ => throw ArgumentError('Invalid interval type'),
    };
  }

  DateTime _snapToTimeDuration(DateTime date, Duration duration) {
    final totalMinutes = date.hour * 60 + date.minute;
    final intervalMinutes = duration.inMinutes;
    final snappedMinutes = (totalMinutes ~/ intervalMinutes) * intervalMinutes;

    return DateTime(
      date.year,
      date.month,
      date.day,
      snappedMinutes ~/ 60,
      snappedMinutes % 60,
    );
  }

  bool isDateWithinInterval(
      DateTime date, DateTime intervalStart, TimelineInterval interval) {
    final intervalEnd = getNextDate(intervalStart, interval);
    return date.isWithinRange(intervalStart, intervalEnd);
  }
}
