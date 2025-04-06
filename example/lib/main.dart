import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/viewmodels/calendar_event_editor_viewmodel.dart'; // Import ViewModel
import 'package:jazmine_calendar/src/views/widgets/editors/calendar_event_editor.dart'; // Import Editor
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:provider/provider.dart'; // Import Provider
import 'dart:io' show Platform; // Import Platform for OS check
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb for web check

// Define extension methods for DateTime to replace the ones from the jazmine_calendar package
extension DateTimeExtensions on DateTime {
  DateTime get dayStarts => DateTime(year, month, day);
  DateTime get dayEnds => DateTime(year, month, day, 23, 59, 59, 999);
}

// Enum to represent user's choice for editing recurring events
enum RecurrenceEditChoice {
  thisEventOnly,
  thisAndFuture,
  // allEvents, // Optional: Add if needed
  cancel,
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
      // Add onEventTap callback
      onEventTap: _handleEventTap,
    );

    // Generate random events
    final random = Random();
    final List<CalendarEvent> mockEvents = [];
    final initialDate = DateTime.now().toUtc().dayStarts;
    // Increase event count slightly more
    final int eventCount = 30 + random.nextInt(21); // 30 to 50 events

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
      // Generate events within a +/- 5 day range for better multi-day spread
      final dayOffset = random.nextInt(11) - 5; // -5 to +5 days
      final eventDate = initialDate.add(Duration(days: dayOffset));

      // Keep start time random for distribution, but force all-day later
      final startHour = random.nextInt(24);
      final startMinute = random.nextInt(4) * 15;
      DateTime startTime =
          eventDate.add(Duration(hours: startHour, minutes: startMinute));

      // --- Generate Random Duration (Non-All-Day) ---
      final bool isAllDayEvent = false; // Make them timed events
      // Random duration between 30 minutes and 4 hours
      final durationMinutes = 30 + random.nextInt(211); // 30 to 240 minutes
      DateTime endTime = startTime.add(Duration(minutes: durationMinutes));

      // Ensure end time doesn't cross midnight for simplicity in this example,
      // or handle multi-day timed events if needed.
      if (endTime.day != startTime.day) {
         endTime = startTime.dayEnds; // Cap at end of the start day
      }

      mockEvents.add(CalendarEvent(
        id: 'mock_$i',
        // Format title with date range
        // Update title format for timed events
        title: 'Event ${i + 1}', // Simpler title
        start: startTime,
        end: endTime,
        isAllDay: isAllDayEvent, // Set to false
        color: eventColors[random.nextInt(eventColors.length)],
      ));
    }

    // Add generated events to the controller
    _calendarController.addEvents(mockEvents);
  }

  // --- Event Interaction Handlers ---

  Future<void> _handleEventTap(CalendarEvent event) async {
    print("Event tapped: ${event.id} (isOccurrence: ${event.isOccurrence})");

    if (event.isOccurrence) {
      // It's an instance of a recurring event, ask the user how to edit
      final choice = await showDialog<RecurrenceEditChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Edit recurring event"), // TODO: Localize
          content: const Text("Do you want to edit only this event, or this and all future events in the series?"), // TODO: Localize
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, RecurrenceEditChoice.cancel),
              child: const Text("Cancel"), // TODO: Localize
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, RecurrenceEditChoice.thisEventOnly),
              child: const Text("This event only"), // TODO: Localize
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, RecurrenceEditChoice.thisAndFuture),
              child: const Text("This and future events"), // TODO: Localize
            ),
            // TODO: Add "All events" option if needed
          ],
        ),
      );

      switch (choice) {
        case RecurrenceEditChoice.thisEventOnly:
          print("Editing this event only: ${event.id} starting at ${event.start}");
          // TODO: Implement exception logic (e.g., create exception event)
          // For now, just open the editor for the specific occurrence instance
          _showOrNavigateToEventEditor(event: event);
          break;
        case RecurrenceEditChoice.thisAndFuture:
           print("Editing this and future events: ${event.originalEventId}");
           // TODO: Implement logic to modify the original event and potentially split the series
           // For now, find the original event and open the editor for it
           final originalEvent = await _findOriginalEvent(event.originalEventId);
           if (originalEvent != null) {
             _showOrNavigateToEventEditor(event: originalEvent);
           } else {
              print("Could not find original event with ID: ${event.originalEventId}");
              // Optionally show an error message to the user
           }
          break;
        case RecurrenceEditChoice.cancel:
        default:
          // Do nothing if cancelled or no choice made
          break;
      }
    } else {
      // Not a recurring event occurrence, just open the editor directly
      _showOrNavigateToEventEditor(event: event);
    }
  }

  // Helper to find the original base event from persistence (replace with actual logic)
  // This is a placeholder - assumes controller can fetch base events by ID
  Future<CalendarEvent?> _findOriginalEvent(String? originalId) async {
     if (originalId == null) return null;
     // In a real app, you might query your persistence layer directly
     // or have a method in the controller like controller.getBaseEventById(originalId)
     // TODO: Replace this placeholder with actual logic to fetch the base event by ID
     // This might involve adding a method like `getBaseEventById(String id)` to CalendarController
     // which interacts with the persistence layer.
     print("Warning: _findOriginalEvent is a placeholder and cannot find the event.");
     return null; // Return null for now
  }

  // Method to navigate to or show the event editor based on platform
  void _showOrNavigateToEventEditor({CalendarEvent? event}) {
    // Common builder function for the editor content
    // It needs the context used for navigation/dialog closing (navContext)
    Widget buildEditorContent(BuildContext navContext) {
      return CalendarEventEditor(
        onCancel: () {
          Navigator.pop(navContext); // Close editor/dialog on cancel
        },
      );
    }

    // Common ViewModel creation logic and save handling
    // This function creates the ViewModel and defines what happens onSave
    ChangeNotifierProvider<CalendarEventEditorViewModel> createViewModelProvider(BuildContext contextForPop) {
       return ChangeNotifierProvider(
          create: (_) => CalendarEventEditorViewModel(
            event: event,
            onSave: (eventFromViewModel) {
              final eventToSave = eventFromViewModel; // ViewModel already includes color etc.

              if (event == null) { // Creating new event
                _calendarController.addEvent(eventToSave);
              } else { // Updating existing event
                // TODO: Handle recurrence update choice here based on original event/occurrence flags
                print("Saving edited event: ${eventToSave.id}");
                // _calendarController.removeEvent(event); // TODO: Implement removeEvent
                _calendarController.addEvent(eventToSave); // Add updated event
                print("Update logic needs CalendarController implementation");
              }
              // Use the context associated with the route/dialog to pop
              Navigator.pop(contextForPop);
            },
          ),
          // We need the child directly, the builder logic is handled by MaterialPageRoute/showDialog
          child: buildEditorContent(contextForPop), // Pass the correct context
       );
    }


    // Platform check
    bool isDesktopOrWeb = false;
    if (kIsWeb) {
      isDesktopOrWeb = true;
    } else {
      // Use try-catch for Platform checks as they aren't available on web
      try {
        isDesktopOrWeb = Platform.isLinux || Platform.isMacOS || Platform.isWindows;
      } catch (e) {
        print("Platform check failed (expected on web): $e");
        isDesktopOrWeb = false; // Assume mobile if check fails
      }
    }

    if (isDesktopOrWeb) {
      // Show as Dialog on Desktop/Web
      showDialog(
        context: context, // Use the main build context to show the dialog
        builder: (dialogContext) => Dialog(
           child: SizedBox(
             width: 500, // Constrain dialog size
             height: 700, // Adjust height as needed
             // Create the provider and editor content, passing the dialog's context
             child: createViewModelProvider(dialogContext),
           ),
        ),
      );
    } else {
      // Push as Full Screen Route on Mobile
      Navigator.push(
        context, // Use the main build context to push the route
        MaterialPageRoute(
          // Create the provider and editor content, passing the route's context
          builder: (routeContext) => createViewModelProvider(routeContext),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold is now inside JazmineCalendar if showCreateEventButton is true
    // We return JazmineCalendar directly
    return JazmineCalendar(
      // Configure the main JazmineCalendar instance directly
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
      showCreateEventButton: true, // Enable the FAB
      onCreateEventButtonPressed: () {
        _showOrNavigateToEventEditor(); // Call the correct method name
      },
      // Pass the callback implementation
      onTimeSlotCreateInteraction: (startTime) {
         print("Grid interaction callback received: $startTime"); // Debug print
        // Open editor, pre-filling the start time
        _showOrNavigateToEventEditor(
          event: CalendarEvent( // Create a dummy event just to pass the start time
             id: '', // ID will be generated by ViewModel if null/empty
             title: '', // Title is empty for new event
             start: startTime,
             // Set a default end time (e.g., 1 hour after start)
             end: startTime.add(_calendarController.intervalNotifier.value), // Access interval via notifier
          )
        );
      },
    );
  }
}

// Removed temporary testing extension
