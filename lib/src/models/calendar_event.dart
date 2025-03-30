import 'dart:ui';

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final Color? color;
  final String? location;
  final String timeZone;
  final bool isAllDay;
  final String? recurrenceType;
  final String? recurrenceRule;
  final List<String>? resourceIds;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.color,
    this.location,
    this.timeZone = 'UTC',
    this.isAllDay = false,
    this.recurrenceType,
    this.recurrenceRule,
    this.resourceIds,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError('End time must be after start time');
    }
  }

  /// Creates a copy of this event with the given fields replaced with new values
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    Color? color,
    String? location,
    String? timeZone,
    bool? isAllDay,
    String? recurrenceType,
    String? recurrenceRule,
    List<String>? resourceIds,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      location: location ?? this.location,
      timeZone: timeZone ?? this.timeZone,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      resourceIds: resourceIds ?? this.resourceIds,
    );
  }

  /// Creates an Event from a JSON map
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      color: json['color'] != null ? Color(json['color'] as int) : null,
      location: json['location'] as String?,
      timeZone: json['timeZone'] as String? ?? 'UTC',
      isAllDay: json['isAllDay'] as bool? ?? false,
      recurrenceType: json['recurrenceType'] as String?,
      recurrenceRule: json['recurrenceRule'] as String?,
      resourceIds: json['resourceIds'] != null
          ? List<String>.from(json['resourceIds'] as List)
          : null,
    );
  }

  /// Converts this Event to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'color': color?.value,
      'location': location,
      'timeZone': timeZone,
      'isAllDay': isAllDay,
      'recurrenceType': recurrenceType,
      'recurrenceRule': recurrenceRule,
      'resourceIds': resourceIds,
    };
  }

  /// Returns the duration of the event
  Duration get duration => end.difference(start);

  /// Checks if this event overlaps with another event
  bool overlaps(CalendarEvent other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.start == start &&
        other.end == end &&
        other.color == color &&
        other.location == location &&
        other.timeZone == timeZone &&
        other.isAllDay == isAllDay &&
        other.recurrenceType == recurrenceType &&
        other.recurrenceRule == recurrenceRule &&
        _listEquals(other.resourceIds, resourceIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      start,
      end,
      color,
      location,
      timeZone,
      isAllDay,
      recurrenceType,
      recurrenceRule,
      resourceIds != null ? Object.hashAll(resourceIds!) : null,
    );
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, start: $start, end: $end)';
  }
}
