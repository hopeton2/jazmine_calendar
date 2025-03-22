import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(MaterialApp(
    title: 'Jazmine Calendar Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,  // This could be any color - the theme will adapt
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,  // This could be any color - the theme will adapt
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    themeMode: ThemeMode.dark,
    home: const MyHomePage(),
  ));
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  JazmineCalendarController? _controller;
  bool _isLoading = true;
  String _lastAction = '';
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final controller = await JazmineCalendarController.create(
        initialView: _currentView,
        showFloatingActionButton: true,
        onEventCreated: _handleEventCreated,
        onEventRescheduled: _handleEventRescheduled,
        onEventResized: _handleEventResized,
      );

      // Clear any existing events
      await controller.clearEvents();

      if (!mounted) return;
      
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize calendar: $e')),
      );
    }
  }

  Future<void> _handleEventCreated(Event event) async {
    if (!mounted) return;
    setState(() {
      _lastAction = 'Created: ${event.title}';
    });
    _showActionSnackBar('Event created: ${event.title}');
  }

  Future<void> _handleEventRescheduled(Event event, DateTime newStart, DateTime newEnd) async {
    if (!mounted) return;
    final formatter = DateFormat('MMM d, HH:mm');
    setState(() {
      _lastAction = 'Rescheduled: ${event.title}\n'
          'From: ${formatter.format(event.start)} → ${formatter.format(newStart)}';
    });
    _showActionSnackBar('Event rescheduled: ${event.title}');
  }

  Future<void> _handleEventResized(Event event, DateTime newStart, DateTime newEnd) async {
    if (!mounted) return;
    final formatter = DateFormat('HH:mm');
    setState(() {
      _lastAction = 'Resized: ${event.title}\n'
          'Duration: ${formatter.format(event.start)} - ${formatter.format(event.end)} → '
          '${formatter.format(newStart)} - ${formatter.format(newEnd)}';
    });
    _showActionSnackBar('Event resized: ${event.title}');
  }

  void _showActionSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addSampleEvents() async {
    if (_controller == null) return;
    
    try {
      final today = DateTime.now();
      final sampleEvents = [
        Event(
          id: 'event1',
          title: 'Morning Stand-up',
          start: DateTime(today.year, today.month, today.day, 9, 30),
          end: DateTime(today.year, today.month, today.day, 10, 0),
          timeZone: 'UTC',
          color: Colors.blue,
        ),
        Event(
          id: 'event2',
          title: 'Lunch Break',
          start: DateTime(today.year, today.month, today.day, 12),
          end: DateTime(today.year, today.month, today.day, 13),
          timeZone: 'UTC',
          location: 'Cafeteria',
          color: Colors.green,
        ),
        Event(
          id: 'event3',
          title: 'Project Review',
          start: DateTime(today.year, today.month, today.day + 1, 14),
          end: DateTime(today.year, today.month, today.day + 1, 16),
          timeZone: 'UTC',
          description: 'Monthly project status review',
          color: Colors.orange,
        ),
        Event(
          id: 'event4',
          title: 'All-day Event',
          start: today,
          end: today.add(const Duration(days: 1)),
          timeZone: 'UTC',
          isAllDay: true,
          color: Colors.purple,
        ),
      ];

      for (final event in sampleEvents) {
        await _controller!.addEvent(event);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add sample events: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_lastAction.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lastAction,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _lastAction = ''),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _controller == null
                      ? const Center(child: CircularProgressIndicator())
                      : JazmineCalendar(
                          controller: _controller,
                          showNavigationBar: true,
                          showViewSelector: true,
 
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Controller is disposed automatically by the JazmineCalendar widget
    super.dispose();
  }
}
