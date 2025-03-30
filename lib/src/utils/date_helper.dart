import 'package:dart_date/dart_date.dart';
import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

/// Utility class for date and time operations in the calendar
abstract class DateHelper {
  static CalendarController? controller;

  /// Returns the first day of the month for a given date
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the last day of the month for a given date
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Returns the number of days in the month for a given date
  static int daysInMonth(DateTime date) {
    return lastDayOfMonth(date).day;
  }

  /// Returns a list of DateTime objects for each day in the given month
  static List<DateTime> daysInMonthList(DateTime date) {
    final firstDay = firstDayOfMonth(date);
    final dayCount = daysInMonth(date);
    return List.generate(dayCount,
        (index) => DateTime(firstDay.year, firstDay.month, index + 1));
  }

  /// Returns the day of week (0-based, 0 = Monday, 6 = Sunday) for the first day of the month
  static int firstDayOfMonthWeekday(DateTime date) {
    final firstDay = firstDayOfMonth(date);
    return firstDayOfWeek(firstDay);
  }

  static int firstDayOfWeek(DateTime date) {
    return (date.weekday - controller!.firstDayOfWeek) % 7;
  }

  static List<DateTime> intervalDates(DateTime date, Duration rowInterval,
      Duration colInterval, int cols, int rows, Axis orientation) {
    final List<DateTime> calendarDates = [];
    date = date.startOfDay;

    if (orientation == Axis.vertical) {
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          calendarDates.add(date.add(colInterval * col).add(rowInterval * row));
        }
      }
    } else {
      for (int col = 0; col < cols; col++) {
        for (int row = 0; row < rows; row++) {
          calendarDates.add(date.add(colInterval * col + rowInterval * row));
        }
      }
    }

    return calendarDates;
  }

  static List<DateTime> intervalDatesForWeek(DateTime date,
      [bool isWorkWeek = false]) {
    final interval = controller!.intervalNotifier.value;
    final firstDay = findFirstDayOfWeek(date);
    final cols = isWorkWeek ? 5 : 7;
    final rows = const Duration(days: 1).inMinutes ~/ interval.inMinutes;
    return intervalDates(
        firstDay, interval, const Duration(days: 1), cols, rows, Axis.vertical);
  }

  static List<DateTime> intervalDatesForMonth(DateTime date) {
    final interval = controller!.intervalNotifier.value;
    final firstDay = firstDayOfMonth(date);
    const cols = 7;
    final rows = const Duration(days: 1).inMinutes ~/ interval.inMinutes;
    return intervalDates(firstDay, interval, const Duration(days: 1), cols,
        rows, Axis.horizontal);
  }

  static List<DateTime> intervalDatesForDay(DateTime date) {
    final interval = controller!.intervalNotifier.value;
    const cols = 1;
    final rows = const Duration(days: 1).inMinutes ~/ interval.inMinutes;
    return intervalDates(
        date, interval, const Duration(days: 1), cols, rows, Axis.vertical);
  }

  /// Returns a list of DateTime objects for the calendar month grid including leading/trailing days
  static List<DateTime> calendarDaysForMonth(DateTime date) {
    final List<DateTime> calendarDays = [];

    // Get the first day of the month
    final firstDay = firstDayOfMonth(date);

    // Get the weekday of the first day (0 = Monday, 6 = Sunday)
    final firstWeekday = firstDayOfMonthWeekday(date);

    // Add days from the previous month
    if (firstWeekday > 0) {
      final prevMonth = DateTime(firstDay.year, firstDay.month - 1);
      final daysInPrevMonth = daysInMonth(prevMonth);

      for (int i = daysInPrevMonth - firstWeekday + 1;
          i <= daysInPrevMonth;
          i++) {
        calendarDays.add(DateTime(prevMonth.year, prevMonth.month, i));
      }
    }

    // Add days from the current month
    final daysCount = daysInMonth(date);
    for (int i = 1; i <= daysCount; i++) {
      calendarDays.add(DateTime(date.year, date.month, i));
    }

    // Add days from the next month to complete the grid (6 rows of 7 days)
    final remainingDays = 42 - calendarDays.length;
    final nextMonth = DateTime(firstDay.year, firstDay.month + 1);

    for (int i = 1; i <= remainingDays; i++) {
      calendarDays.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    return calendarDays;
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Check if a date is a weekend (Saturday or Sunday)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Convert DateTime to a specific timezone
  static DateTime convertToTimeZone(DateTime dateTime, String timeZoneId) {
    try {
      final location = tz.getLocation(timeZoneId);
      final zonedTime = tz.TZDateTime.from(dateTime, location);
      return DateTime(
        zonedTime.year,
        zonedTime.month,
        zonedTime.day,
        zonedTime.hour,
        zonedTime.minute,
        zonedTime.second,
      );
    } catch (e) {
      return dateTime; // Return original date time if timezone is invalid
    }
  }

  /// Generate a list of all available time zones
  static List<String> getAvailableTimeZones() {
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  /// Get a formatted time range string for an event
  static String formatTimeRange(
      DateTime start, DateTime end, String formatPattern) {
    // Create formatter
    final formatter = DateFormat(formatPattern);
    // Convert to local timezone and format
    final startFormatted = formatter.format(start);
    final endFormatted = formatter.format(end);
    return '$startFormatted - $endFormatted';
  }

  /// Returns the first day of the week for a given date (Monday)
  static DateTime findFirstDayOfWeek(DateTime date) {
    int difference = date.weekday - DateTime.monday;
    if (difference < 0) difference += 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: difference));
  }

  /// Calculate the number of days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}
