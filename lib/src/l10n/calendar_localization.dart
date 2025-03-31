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

  /// Initialize the localized strings based on the locale
  Future<bool> load() async {
    // Initialize date formatting for the locale
    await initializeDateFormatting(locale.languageCode, null);

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

  // Date formats
  String formatYearMonth(DateTime date) {
    return DateFormat.yMMMM(locale.languageCode).format(date);
  }

  String formatMonthDay(DateTime date) {
    return DateFormat.MMMd(locale.languageCode).format(date);
  }

  String formatFullDate(DateTime date) {
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }

  String formatMonthYear(DateTime date) {
    return DateFormat('MMM y', locale.languageCode).format(date);
  }

  String formatDateRange(DateTime start, DateTime end) {
    if (start == end) {
      return formatFullDate(start);
    }

    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat.MMMd(locale.languageCode).format(start)} - ${DateFormat.d(locale.languageCode).format(end)}, ${start.year}';
    }

    return '${DateFormat.MMMd(locale.languageCode).format(start)} - ${DateFormat.yMMMd(locale.languageCode).format(end)}';
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
