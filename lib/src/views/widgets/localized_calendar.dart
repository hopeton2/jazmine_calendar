import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

/// A wrapper widget that provides localization for the JazmineCalendar.
class LocalizedCalendar extends StatelessWidget {
  /// The JazmineCalendar widget to be localized.
  final JazmineCalendar calendar;

  /// The locale to use for the calendar.
  final Locale? locale;

  /// Creates a localized calendar widget.
  const LocalizedCalendar({
    super.key,
    required this.calendar,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        CalendarLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: CalendarLocalization.supportedLocales,
      theme: Theme.of(context),
      home: calendar,
    );
  }
}
