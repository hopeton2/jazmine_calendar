import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';

void main() {
  // Initialize date formatting for tests
  initializeDateFormatting('en', null);
  group('CalendarLocalization', () {
    testWidgets('loads English strings by default',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('en'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, 'Day');
      expect(localizations.workWeekViewLabel, 'Work Week');
      expect(localizations.weekViewLabel, 'Week');
      expect(localizations.monthViewLabel, 'Month');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Timeline');
      expect(localizations.today, 'Today');
      expect(localizations.selectDate, 'Select Date');
    });

    testWidgets('loads French strings for fr locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('fr'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, 'Jour');
      expect(localizations.workWeekViewLabel, 'Semaine de travail');
      expect(localizations.weekViewLabel, 'Semaine');
      expect(localizations.monthViewLabel, 'Mois');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Chronologie');
      expect(localizations.today, 'Aujourd\'hui');
      expect(localizations.selectDate, 'Sélectionner une date');
    });

    testWidgets('loads German strings for de locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('de'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, 'Tag');
      expect(localizations.workWeekViewLabel, 'Arbeitswoche');
      expect(localizations.weekViewLabel, 'Woche');
      expect(localizations.monthViewLabel, 'Monat');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Zeitachse');
      expect(localizations.today, 'Heute');
      expect(localizations.selectDate, 'Datum auswählen');
    });

    testWidgets('falls back to English for unsupported locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('es'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, 'Day');
      expect(localizations.workWeekViewLabel, 'Work Week');
      expect(localizations.weekViewLabel, 'Week');
      expect(localizations.monthViewLabel, 'Month');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Timeline');
      expect(localizations.today, 'Today');
      expect(localizations.selectDate, 'Select Date');
    });

    testWidgets('formats dates according to locale',
        (WidgetTester tester) async {
      final enLocalizations = CalendarLocalization(const Locale('en'));
      await enLocalizations.load();

      final date = DateTime(2023, 5, 15);

      // We can only reliably test English formatting without initializing all locales
      // Test formatYearMonth
      expect(enLocalizations.formatYearMonth(date), 'May 2023');

      // Test formatMonthDay
      expect(enLocalizations.formatMonthDay(date), 'May 15');

      // Test formatFullDate
      expect(enLocalizations.formatFullDate(date), 'May 15, 2023');
    });
  });
}
