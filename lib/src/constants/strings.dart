import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';

/// Class that provides localized strings for the Jazmine Calendar.
/// This is a wrapper around CalendarLocalization to maintain backward compatibility.
class CalendarStrings {
  /// Get the localized day view label
  static String dayViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).dayViewLabel;
  }

  /// Get the localized work week view label
  static String workWeekViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).workWeekViewLabel;
  }

  /// Get the localized week view label
  static String weekViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).weekViewLabel;
  }

  /// Get the localized month view label
  static String monthViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).monthViewLabel;
  }

  /// Get the localized agenda view label
  static String agendaViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).agendaViewLabel;
  }

  /// Get the localized timeline view label
  static String timelineViewLabel(BuildContext context) {
    return CalendarLocalization.of(context).timelineViewLabel;
  }

  /// Get the localized today button label
  static String today(BuildContext context) {
    return CalendarLocalization.of(context).today;
  }

  /// Get the localized select date label
  static String selectDate(BuildContext context) {
    return CalendarLocalization.of(context).selectDate;
  }
}
