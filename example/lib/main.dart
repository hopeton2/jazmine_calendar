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
      initialView: CalendarViewType.day,
      initialDate: DateTime.now(),
      scrollToCurrentTimeOnLoad: false,
      interval: const Duration(minutes: 60),
    );

    // Configure the vertical indicator
    // Note: This would be the ideal place to configure the EventRenderStyle
    // if the CalendarController had a parameter for it

    // Generate random events (similar logic from ViewModel)
    final random = Random();
    final List<CalendarEvent> mockEvents = [];
    // Generate events around the initial date for better visibility
    // Use DateTime.now() as the base for generating event dates
    final initialDate = DateTime.now().toUtc().dayStarts;
    final int eventCount = 15 + random.nextInt(16); // 15 to 30 events

    const List<Color> eventColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    for (int i = 0; i < eventCount; i++) {
      // Generate events within a +/- 3 day range of the initial date
      final dayOffset = random.nextInt(7) - 3; // -3 to +3 days
      final eventDate = initialDate.add(Duration(days: dayOffset));

      final startHour = random.nextInt(24);
      final startMinute = random.nextInt(4) * 15;
      final durationMinutes = (2 + random.nextInt(191)) * 15; // 30m to 48h

      DateTime startTime =
          eventDate.add(Duration(hours: startHour, minutes: startMinute));
      DateTime endTime = startTime.add(Duration(minutes: durationMinutes));
      // --- Force All-Day Events ---
      const bool isAllDayEvent = true; // Always create all-day events

      startTime = startTime.dayStarts; // Start at the beginning of the day
      // Allow slightly longer duration, e.g., 1 to 4 days
      int allDayDurationDays = 1 + random.nextInt(4);
      endTime = startTime.add(Duration(days: allDayDurationDays));
      // Removed the 'else' block for timed events

      mockEvents.add(CalendarEvent(
        id: 'mock_$i',
        // Format title with date range
        title: 'Event ${i + 1} (${DateFormat.yMd().format(startTime)} - ${DateFormat.yMd().format(endTime.subtract(const Duration(microseconds: 1)))})', // Subtract microsecond to show correct end date
        start: startTime,
        end: endTime,
        isAllDay: isAllDayEvent,
        color: eventColors[random.nextInt(eventColors.length)],
      ));
    }

    // Add generated events to the controller
    // Assuming an addEvents method exists on CalendarController
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
        // Configure the vertical indicator through the dayConfiguration
        dayConfiguration: const DayViewConfiguration(
          hourHeight: 60,
          timebarWidth: 60,
          showCurrentTimeIndicator: true,
        ),
        // Note: In a real app, you would configure the vertical indicator through a custom theme
        // that includes an EventRenderStyle with the desired verticalIndicatorWidth and color
      ),
    );
  }
}
