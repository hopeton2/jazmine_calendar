import '../models/event.dart';

class EventPosition {
  final Event event;
  final double top;
  final double left;
  final double width;
  final double height;

  EventPosition({
    required this.event,
    required this.left,
    required this.width,
    required this.top,
    required this.height,
  });
}

class EventPacker {
  static List<EventPosition> packEvents({
    required List<Event> events,
    required double containerWidth,
    required double hourHeight,
  }) {
    if (events.isEmpty) return [];

    // Sort events by start time
    final sortedEvents = List<Event>.from(events)
      ..sort((a, b) => a.start.compareTo(b.start));

    // Group overlapping events
    final groups = _groupOverlappingEvents(sortedEvents);

    // Pack each group
    final positions = <EventPosition>[];
    for (final group in groups) {
      positions.addAll(_packGroup(
        group,
        containerWidth: containerWidth,
        hourHeight: hourHeight,
      ));
    }

    return positions;
  }

  static List<List<Event>> _groupOverlappingEvents(List<Event> sortedEvents) {
    if (sortedEvents.isEmpty) return [];

    final groups = <List<Event>>[];
    var currentGroup = <Event>[sortedEvents.first];

    for (var i = 1; i < sortedEvents.length; i++) {
      final event = sortedEvents[i];
      final lastEvent = currentGroup.last;

      if (event.start.isBefore(lastEvent.end)) {
        currentGroup.add(event);
      } else {
        groups.add(currentGroup);
        currentGroup = <Event>[event];
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  static List<EventPosition> _packGroup(
    List<Event> group, {
    required double containerWidth,
    required double hourHeight,
  }) {
    final count = group.length;
    final positions = <EventPosition>[];
    final columnWidth = containerWidth / count;

    for (var i = 0; i < group.length; i++) {
      final event = group[i];
      final startHour = event.start.hour + (event.start.minute / 60);
      final duration = event.end.difference(event.start).inMinutes / 60;

      positions.add(
        EventPosition(
          event: event,
          top: startHour * hourHeight,
          left: i * columnWidth,
          width: columnWidth,
          height: duration * hourHeight,
        ),
      );
    }

    return positions;
  }
}
