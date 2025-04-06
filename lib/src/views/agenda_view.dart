import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';

class AgendaView extends BaseCalendarView {
  final AgendaViewConfiguration configuration;

  const AgendaView({
    super.key,
    this.configuration = const AgendaViewConfiguration(),
  });

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      startDate, DateTime selectedDate) {
    return ValueListenableBuilder<List<CalendarEvent>>(
      valueListenable: _createEventsNotifier(controller),
      builder: (context, events, child) {
        if (events.isEmpty) {
          return const Center(child: Text('No events'));
        }

        events.sort((a, b) => a.start.compareTo(b.start));

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isFirstOfDay =
                index == 0 || !_isSameDay(events[index - 1].start, event.start);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstOfDay) _buildDateHeader(event.start),
                _buildAgendaItem(context, event),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to create and manage the events notifier for the Agenda view
  ValueNotifier<List<CalendarEvent>> _createEventsNotifier(CalendarController controller) {
    final notifier = ValueNotifier<List<CalendarEvent>>([]);
    late final VoidCallback controllerListener;

    // Function to fetch events for the agenda range
    Future<void> fetchAgendaEvents() async {
      // Define the date range for the agenda (e.g., 1 month before to 3 months after current start date)
      final agendaStartDate = controller.startDate.subtract(const Duration(days: 30));
      final agendaEndDate = controller.startDate.add(const Duration(days: 90)); // Adjust range as needed

      try {
        final events = await controller.getEventsForDateRange(agendaStartDate, agendaEndDate);
        // Sort events before updating the notifier
        events.sort((a, b) => a.start.compareTo(b.start));
        if (notifier.value != events) { // Basic check to avoid unnecessary updates
           notifier.value = events;
        }
      } catch (e) {
         print("Error fetching events for AgendaView: $e");
         notifier.value = []; // Clear on error
      }
    }

    // Listener to refetch when relevant controller state changes
    controllerListener = () {
       // Refetch when date/view changes or event data changes
       fetchAgendaEvents();
    };

    // Add listener to controller's relevant notifiers
    controller.startDateNotifier.addListener(controllerListener);
    controller.eventDataChangeNotifier.addListener(controllerListener);
    // Optionally listen to currentViewNotifier if agenda range depends on it

    // Initial fetch
    fetchAgendaEvents();

    // Return a wrapper notifier that removes the listener on dispose
    // Pass the initial value of the notifier, not the notifier itself
    return _ManagedValueNotifier(notifier.value, () {
       controller.startDateNotifier.removeListener(controllerListener);
       controller.eventDataChangeNotifier.removeListener(controllerListener);
    });
  }

  Widget _buildDateHeader(DateTime date) {
    final dateFormat = DateFormat.yMMMMEEEEd();
    return Container(
      padding: configuration.dateDividerPadding,
      color: Colors.grey[100],
      child: Align(
        alignment: configuration.dateAlignment,
        child: Text(
          dateFormat.format(date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaItem(BuildContext context, CalendarEvent event) {
    final timeFormat = DateFormat.jm();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              timeFormat.format(event.start),
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.location != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.location!,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Helper class to manage listener removal on dispose
class _ManagedValueNotifier<T> extends ValueNotifier<T> {
  final VoidCallback _onDispose;

  _ManagedValueNotifier(super.value, this._onDispose);

  @override
  void dispose() {
    _onDispose();
    super.dispose();
  }
}
