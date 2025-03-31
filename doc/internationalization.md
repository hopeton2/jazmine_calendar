# Internationalization in Jazmine Calendar

Jazmine Calendar supports internationalization (i18n) out of the box, with built-in support for:

- English (en)
- French (fr)
- German (de)

## Using Internationalization

### Option 1: Using MaterialApp with Localization Delegates

Add the localization delegates and supported locales to your MaterialApp:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  runApp(MaterialApp(
    localizationsDelegates: const [
      CalendarLocalization.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: CalendarLocalization.supportedLocales, // [en, fr, de]
    locale: const Locale('fr'), // Set the locale to French
    home: Scaffold(
      body: JazmineCalendar(),
    ),
  ));
}
```

### Option 2: Using LocalizedCalendar Widget

Use the `LocalizedCalendar` widget to wrap your `JazmineCalendar`:

```dart
import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: LocalizedCalendar(
        locale: const Locale('de'), // German
        calendar: JazmineCalendar(),
      ),
    ),
  ));
}
```

## Adding a New Language

To add support for a new language:

1. Create a new file in `lib/src/l10n/` named `strings_<language_code>.dart` (e.g., `strings_es.dart` for Spanish)

2. Define the translations in the file:

```dart
/// Spanish strings for the Jazmine Calendar
final Map<String, String> spanishStrings = {
  // Calendar view labels
  'dayViewLabel': 'Día',
  'workWeekViewLabel': 'Semana laboral',
  'weekViewLabel': 'Semana',
  'monthViewLabel': 'Mes',
  'agendaViewLabel': 'Agenda',
  'timelineViewLabel': 'Línea de tiempo',

  // Navigation buttons
  'today': 'Hoy',
  'selectDate': 'Seleccionar fecha',
};
```

3. Update the `CalendarLocalization` class in `lib/src/l10n/calendar_localization.dart`:

   - Add the import for your new language file
   - Add the language code to the `supportedLocales` list
   - Update the `load()` method to handle the new language

4. Add tests for the new language in `test/l10n/calendar_localization_test.dart`

## Date Formatting

The `CalendarLocalization` class provides methods for formatting dates according to the current locale:

- `formatYearMonth(DateTime date)`: Formats a date as "Month Year" (e.g., "May 2023")
- `formatMonthDay(DateTime date)`: Formats a date as "Month Day" (e.g., "May 15")
- `formatFullDate(DateTime date)`: Formats a date as "Month Day, Year" (e.g., "May 15, 2023")
- `formatMonthYear(DateTime date)`: Formats a date as "Month Year" (e.g., "May 2023")
- `formatDateRange(DateTime start, DateTime end)`: Formats a date range

These methods use the `intl` package's `DateFormat` class with the appropriate locale.
