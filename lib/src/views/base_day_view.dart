import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/jazmine_calendar_controller.dart';
import '../models/event.dart';
import '../theme/jazmine_calendar_theme.dart';
import 'package:intl/intl.dart';
import 'configurations.dart';

class BaseDayView extends StatelessWidget {
  final List<DateTime> days;
  final Duration interval;
  final double hourHeight;
  final bool showCurrentTimeIndicator;
  final BaseViewConfiguration configuration;

  const BaseDayView({
    super.key,
    required this.days,
    required this.configuration,
    this.interval = const Duration(minutes: 30),
    this.hourHeight = 60,
    this.showCurrentTimeIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        return ValueListenableBuilder<List<Event>>(
          valueListenable: controller.eventsNotifier,
          builder: (context, events, child) {
            return Column(
              children: [
                _buildHeader(days),
                Expanded(
                  child: Row(
                    children: [
                      _buildTimeColumn(),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: days.map((date) {
                            final dayEvents = _getEventsForDate(events, date);
                            final allDayEvents = _getAllDayEventsForDate(events, date);
                            return Expanded(
                              child: _buildDayColumn(
                                context,
                                date,
                                dayEvents,
                                allDayEvents,
                                controller,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(List<DateTime> days) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50),
          ...days.map((date) => Expanded(
            child: Align(
              alignment: configuration.dateAlignment,
              child: Text(
                DateFormat('E d').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    final slotsPerDay = Duration(hours: 24).inMinutes ~/ interval.inMinutes;
    
    return SizedBox(
      width: 50,
      child: ListView.builder(
        itemCount: slotsPerDay,
        itemBuilder: (context, index) {
          final minutes = index * interval.inMinutes;
          final hour = minutes ~/ 60;
          final minute = minutes % 60;
          
          return SizedBox(
            height: 60, // Height per slot
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    DateTime date,
    List<Event> events,
    List<Event> allDayEvents,
    JazmineCalendarController controller,
  ) {
    final slotsPerDay = const Duration(hours: 24).inMinutes ~/ interval.inMinutes;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: ListView.builder(
        itemCount: slotsPerDay,
        itemBuilder: (context, index) {
          final slotStart = DateTime(
            date.year,
            date.month,
            date.day,
            0,
            index * interval.inMinutes,
          );
          
          final slotEnd = slotStart.add(interval);
          
          final slotEvents = events.where((event) =>
            event.start.isBefore(slotEnd) && 
            event.end.isAfter(slotStart)
          ).toList();

          return Container(
            height: 60, // Height per slot
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Stack(
              children: [
                ...slotEvents.map((event) => _buildEventTile(context, event, slotStart)),
                if (index == 0) ...allDayEvents.map((event) => _buildAllDayEventTile(context, event)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event, DateTime slotStart) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    
    final startMinutes = event.start.hour * 60 + event.start.minute;
    final endMinutes = event.end.hour * 60 + event.end.minute;
    final duration = endMinutes - startMinutes;
    final height = (duration / interval.inMinutes) * 60;
    final top = ((startMinutes - (slotStart.hour * 60 + slotStart.minute)) / interval.inMinutes) * 60;

    if (top < 0) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: calendarTheme?.getEventBackgroundColor(context) ?? Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAllDayEventTile(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final eventColor = calendarTheme?.getEventBackgroundColor(context) ?? Colors.blue;
    
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: eventColor),
      ),
      padding: const EdgeInsets.all(2),
      child: Text(
        event.title,
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<Event> _getEventsForDate(List<Event> events, DateTime date) {
    return events.where((event) {
      if (event.isAllDay) return false;
      final eventStart = DateTime(event.start.year, event.start.month, event.start.day);
      return date.year == eventStart.year && 
             date.month == eventStart.month && 
             date.day == eventStart.day;
    }).toList();
  }

  List<Event> _getAllDayEventsForDate(List<Event> events, DateTime date) {
    return events.where((event) {
      if (!event.isAllDay) return false;
      final eventStart = DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);
      return date.isAfter(eventStart.subtract(const Duration(days: 1))) && 
             date.isBefore(eventEnd.add(const Duration(days: 1)));
    }).toList();
  }
}


