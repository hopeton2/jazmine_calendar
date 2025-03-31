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
      expect(localizations.allDay, 'All Day');
      expect(localizations.dateLabel, 'Date');
      expect(localizations.monthLabel, 'Month');
      expect(localizations.weekLabel, 'Week');
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
      expect(localizations.allDay, 'Toute la journée');
      expect(localizations.dateLabel, 'Date');
      expect(localizations.monthLabel, 'Mois');
      expect(localizations.weekLabel, 'Semaine');
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
      expect(localizations.allDay, 'Ganztägig');
      expect(localizations.dateLabel, 'Datum');
      expect(localizations.monthLabel, 'Monat');
      expect(localizations.weekLabel, 'Woche');
    });

    testWidgets('loads Spanish strings for es locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('es'));
      await localizations.load();

      expect(localizations.dayViewLabel, 'Día');
      expect(localizations.workWeekViewLabel, 'Semana laboral');
      expect(localizations.weekViewLabel, 'Semana');
      expect(localizations.monthViewLabel, 'Mes');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Línea de tiempo');
      expect(localizations.today, 'Hoy');
      expect(localizations.selectDate, 'Seleccionar fecha');
      expect(localizations.allDay, 'Todo el día');
      expect(localizations.dateLabel, 'Fecha');
      expect(localizations.monthLabel, 'Mes');
      expect(localizations.weekLabel, 'Semana');
    });

    testWidgets('falls back to English for unsupported locale',
        (WidgetTester tester) async {
      final localizations =
          CalendarLocalization(const Locale('pt')); // Portuguese
      await localizations.load();

      expect(localizations.dayViewLabel, 'Day');
      expect(localizations.workWeekViewLabel, 'Work Week');
      expect(localizations.weekViewLabel, 'Week');
      expect(localizations.monthViewLabel, 'Month');
      expect(localizations.agendaViewLabel, 'Agenda');
      expect(localizations.timelineViewLabel, 'Timeline');
      expect(localizations.today, 'Today');
      expect(localizations.selectDate, 'Select Date');
      expect(localizations.allDay, 'All Day');
      expect(localizations.dateLabel, 'Date');
      expect(localizations.monthLabel, 'Month');
      expect(localizations.weekLabel, 'Week');
    });

    testWidgets('formats dates according to locale',
        (WidgetTester tester) async {
      // Initialize English localization
      final enLocalizations = CalendarLocalization(const Locale('en'));
      await enLocalizations.load();

      // Initialize Spanish localization
      final esLocalizations = CalendarLocalization(const Locale('es'));
      await esLocalizations.load();

      final date = DateTime(2023, 5, 15);

      // Test English date formatting
      expect(enLocalizations.formatYearMonth(date), 'May 2023');
      expect(enLocalizations.formatMonthDay(date), 'May 15');
      expect(enLocalizations.formatFullDate(date), 'May 15, 2023');

      // Test Spanish date formatting
      expect(esLocalizations.formatMonthYear(date), 'mayo de 2023');
      expect(esLocalizations.formatFullDate(date), '15 de mayo de 2023');

      // Test date range formatting
      final startDate = DateTime(2023, 5, 15);
      final endDate = DateTime(2023, 5, 20);
      expect(esLocalizations.formatDateRange(startDate, endDate),
          '15 - 20 de mayo de 2023');

      final endDateDifferentMonth = DateTime(2023, 6, 20);
      expect(esLocalizations.formatDateRange(startDate, endDateDifferentMonth),
          '15 de mayo - 20 de junio de 2023');
    });
  });
}
