import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

// Define extension methods for DateTime to replace the ones from the jazmine_calendar package
extension DateTimeExtensions on DateTime {
  DateTime get dayStarts => DateTime(year, month, day);
  DateTime get dayEnds => DateTime(year, month, day, 23, 59, 59, 999);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    title: 'Jazmine Calendar Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurpleAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    localizationsDelegates: const [
      CalendarLocalization.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: CalendarLocalization.supportedLocales,
    //locale: const Locale('fr'), // Set French as the default language
    home: const MyHomePage(),
    themeMode: ThemeMode.dark,
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CalendarController _calendarController; // Store controller instance

  @override
  void initState() {
    super.initState();
    _generateAndAddEvents();
  }

  void _generateAndAddEvents() {
    // Initialize controller
    _calendarController = CalendarController(
      // Start with Week view to better see multi-day events
      initialView: CalendarViewType.week,
      initialDate: DateTime.now(),
      scrollToCurrentTimeOnLoad: false,
      interval: const Duration(minutes: 60),
    );

    // Generate random events
    final random = Random();
    final List<CalendarEvent> mockEvents = [];
    final initialDate = DateTime.now().toUtc().dayStarts;
    // Increase event count slightly more
    final int eventCount = 30 + random.nextInt(21); // 30 to 50 events

    const List<Color> eventColors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
    ];

    for (int i = 0; i < eventCount; i++) {
      // Generate events within a +/- 5 day range for better multi-day spread
      final dayOffset = random.nextInt(11) - 5; // -5 to +5 days
      final eventDate = initialDate.add(Duration(days: dayOffset));

      // Keep start time random for distribution, but force all-day later
      final startHour = random.nextInt(24);
      final startMinute = random.nextInt(4) * 15;
      DateTime startTime = eventDate.add(Duration(hours: startHour, minutes: startMinute));

      // --- Force All-Day Events with Random Duration ---
      const bool isAllDayEvent = true;
      startTime = startTime.dayStarts; // Ensure it starts at the beginning of the day
      // Random duration between 1 and 5 days (inclusive)
      int allDayDurationDays = 1 + random.nextInt(5);
      DateTime endTime = startTime.add(Duration(days: allDayDurationDays));

      mockEvents.add(CalendarEvent(
        id: 'mock_$i',
        // Format title with date range
        title: 'Event ${i + 1} (${DateFormat.yMd().format(startTime)} - ${DateFormat.yMd().format(endTime.subtract(const Duration(microseconds: 1)))})',
        start: startTime,
        end: endTime,
        isAllDay: isAllDayEvent,
        color: eventColors[random.nextInt(eventColors.length)],
      ));
    }

    // Add generated events to the controller
     _calendarController.addEvents(mockEvents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: JazmineCalendar(
        showNavigationBar: true,
        showViewSelector: true,
        navigationBarStyle: NavigationBarStyle.compact,
        controller: _calendarController, // Use the initialized controller
        dayConfiguration: const DayViewConfiguration(
          hourHeight: 60,
          timebarWidth: 60,
          showCurrentTimeIndicator: true,
        ),
        // Add configurations for other views if needed
        // Ensure WeekViewConfiguration exists and uses appropriate parameters
        // Relying on defaults or inherited values for timebar/hour height for now
        weekConfiguration: const WeekViewConfiguration(
           showCurrentTimeIndicator: true,
        ),
        // Removed workWeekConfiguration as it's likely not a separate parameter
      ),
    );
  }
}
