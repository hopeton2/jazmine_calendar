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

  ValueNotifier<List<CalendarEvent>> _createEventsNotifier(
      CalendarController controller) {
    final notifier = ValueNotifier<List<CalendarEvent>>([]);

    Future.microtask(() async {
      final events = await controller.getAllEvents();
      notifier.value = events;
    });

    return notifier;
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
