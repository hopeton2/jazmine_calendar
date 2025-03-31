import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';

void main() {
  // Initialize date formatting for tests
  initializeDateFormatting('en', null);
  
  group('CalendarLocalization for Hindi and Chinese', () {
    testWidgets('loads Hindi strings for hi locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('hi'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, 'दिन');
      expect(localizations.workWeekViewLabel, 'कार्य सप्ताह');
      expect(localizations.weekViewLabel, 'सप्ताह');
      expect(localizations.monthViewLabel, 'महीना');
      expect(localizations.agendaViewLabel, 'एजेंडा');
      expect(localizations.timelineViewLabel, 'टाइमलाइन');
      expect(localizations.today, 'आज');
      expect(localizations.selectDate, 'तारीख़ चुनें');
      expect(localizations.allDay, 'पूरा दिन');
      expect(localizations.dateLabel, 'तारीख');
      expect(localizations.monthLabel, 'महीना');
      expect(localizations.weekLabel, 'सप्ताह');
    });

    testWidgets('loads Chinese strings for zh locale',
        (WidgetTester tester) async {
      final localizations = CalendarLocalization(const Locale('zh'));
      await localizations.load();
      
      expect(localizations.dayViewLabel, '日');
      expect(localizations.workWeekViewLabel, '工作周');
      expect(localizations.weekViewLabel, '周');
      expect(localizations.monthViewLabel, '月');
      expect(localizations.agendaViewLabel, '议程');
      expect(localizations.timelineViewLabel, '时间轴');
      expect(localizations.today, '今天');
      expect(localizations.selectDate, '选择日期');
      expect(localizations.allDay, '全天');
      expect(localizations.dateLabel, '日期');
      expect(localizations.monthLabel, '月份');
      expect(localizations.weekLabel, '周');
    });
  });
}
