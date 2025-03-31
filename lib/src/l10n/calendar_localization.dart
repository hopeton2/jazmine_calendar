import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:jazmine_calendar/src/l10n/strings_en.dart';
import 'package:jazmine_calendar/src/l10n/strings_fr.dart';
import 'package:jazmine_calendar/src/l10n/strings_de.dart';
import 'package:jazmine_calendar/src/l10n/strings_es.dart';

/// Class that provides localized strings for the Jazmine Calendar.
class CalendarLocalization {
  final Locale locale;

  CalendarLocalization(this.locale);

  /// Helper method to keep the code in the widgets concise
  static CalendarLocalization of(BuildContext context) {
    return Localizations.of<CalendarLocalization>(
        context, CalendarLocalization)!;
  }

  /// Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<CalendarLocalization> delegate =
      _CalendarLocalizationDelegate();

  /// List of supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('fr'), // French
    Locale('de'), // German
    Locale('es'), // Spanish
  ];

  /// Map of localized string getters
  late final Map<String, String> _localizedStrings;

  /// Date formatter for full dates
  late final DateFormat _dateFormatter;

  /// Initialize the localized strings based on the locale
  Future<bool> load() async {
    // Initialize date formatting for the locale
    await initializeDateFormatting(locale.languageCode);

    // Load the language strings
    switch (locale.languageCode) {
      case 'en':
        _localizedStrings = englishStrings;
        break;
      case 'fr':
        _localizedStrings = frenchStrings;
        break;
      case 'de':
        _localizedStrings = germanStrings;
        break;
      case 'es':
        _localizedStrings = spanishStrings;
        break;
      default:
        _localizedStrings = englishStrings;
    }

    // Initialize the date formatter after locale is loaded
    if (locale.languageCode == 'es') {
      // Use custom Spanish date format
      _dateFormatter = DateFormat(
          _localizedStrings['fullDateFormat'] ?? 'd \'de\' MMMM \'de\' y',
          locale.languageCode);
    } else {
      // Use standard date format for other languages
      _dateFormatter = DateFormat.yMMMd(locale.languageCode);
    }
    return true;
  }

  /// Get a localized string by key
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Calendar view labels
  String get dayViewLabel => translate('dayViewLabel');
  String get workWeekViewLabel => translate('workWeekViewLabel');
  String get weekViewLabel => translate('weekViewLabel');
  String get monthViewLabel => translate('monthViewLabel');
  String get agendaViewLabel => translate('agendaViewLabel');
  String get timelineViewLabel => translate('timelineViewLabel');

  // Navigation buttons
  String get today => translate('today');
  String get selectDate => translate('selectDate');

  // Calendar labels
  String get allDay => translate('allDay');
  String get dateLabel => translate('dateLabel');
  String get monthLabel => translate('monthLabel');
  String get weekLabel => translate('weekLabel');

  // Date formats
  String formatYearMonth(DateTime date) {
    return DateFormat.yMMMM(locale.languageCode).format(date);
  }

  String formatMonthDay(DateTime date) {
    return DateFormat.MMMd(locale.languageCode).format(date);
  }

  String formatFullDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  String formatMonthYear(DateTime date) {
    if (locale.languageCode == 'es') {
      // Use custom Spanish month-year format
      return DateFormat(_localizedStrings['monthYearFormat'] ?? 'MMMM \'de\' y',
              locale.languageCode)
          .format(date);
    } else {
      // Use standard format for other languages
      return DateFormat('MMM y', locale.languageCode).format(date);
    }
  }

  String formatDateRange(DateTime start, DateTime end) {
    if (start == end) {
      return formatFullDate(start);
    }

    if (locale.languageCode == 'es') {
      // Spanish-specific date range formatting
      if (start.year == end.year && start.month == end.month) {
        // Same month and year: "15 - 20 de mayo de 2023"
        return '${DateFormat.d(locale.languageCode).format(start)} - ${DateFormat.d(locale.languageCode).format(end)} de ${DateFormat.MMMM(locale.languageCode).format(start)} de ${start.year}';
      } else if (start.year == end.year) {
        // Same year, different months: "15 de mayo - 20 de junio de 2023"
        return '${DateFormat.d(locale.languageCode).format(start)} de ${DateFormat.MMMM(locale.languageCode).format(start)} - ${DateFormat.d(locale.languageCode).format(end)} de ${DateFormat.MMMM(locale.languageCode).format(end)} de ${start.year}';
      } else {
        // Different years: "15 de mayo de 2023 - 20 de junio de 2024"
        return '${DateFormat.d(locale.languageCode).format(start)} de ${DateFormat.MMMM(locale.languageCode).format(start)} de ${start.year} - ${DateFormat.d(locale.languageCode).format(end)} de ${DateFormat.MMMM(locale.languageCode).format(end)} de ${end.year}';
      }
    } else {
      // Standard formatting for other languages
      if (start.year == end.year && start.month == end.month) {
        return '${DateFormat.MMMd(locale.languageCode).format(start)} - ${DateFormat.d(locale.languageCode).format(end)}, ${start.year}';
      }

      return '${DateFormat.MMMd(locale.languageCode).format(start)} - ${DateFormat.yMMMd(locale.languageCode).format(end)}';
    }
  }
}

/// LocalizationsDelegate implementation for CalendarLocalization
class _CalendarLocalizationDelegate
    extends LocalizationsDelegate<CalendarLocalization> {
  const _CalendarLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'de', 'es'].contains(locale.languageCode);
  }

  @override
  Future<CalendarLocalization> load(Locale locale) async {
    final localizations = CalendarLocalization(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_CalendarLocalizationDelegate old) => false;
}
