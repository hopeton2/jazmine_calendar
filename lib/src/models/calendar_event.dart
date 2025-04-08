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
  final bool reminderEnabled;
  final int? reminderMinutesBefore; // Minutes before start time
  final bool isPrivate;
  final bool isOccurrence; // Flag indicating if this is an instance of a recurring event
  final String? originalEventId; // ID of the original recurring event if isOccurrence is true

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
    this.reminderEnabled = false,
    this.reminderMinutesBefore,
    this.isPrivate = false, // Default to public
    this.isOccurrence = false, // Default to false
    this.originalEventId, // Null by default
  }) {
    // Add validation: originalEventId must be null if isOccurrence is false
    if (!isOccurrence && originalEventId != null) {
      throw ArgumentError('originalEventId must be null if isOccurrence is false.');
    }
    if (reminderEnabled && reminderMinutesBefore == null) {
      throw ArgumentError('reminderMinutesBefore must be set if reminderEnabled is true');
    }
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
    bool? reminderEnabled,
    int? reminderMinutesBefore, // Allow nullable for clearing
    bool? isPrivate,
    bool? isOccurrence, // Allow copying these flags
    String? originalEventId,
  }) {
    // Handle reminder logic carefully in copyWith
    final bool effectiveReminderEnabled = reminderEnabled ?? this.reminderEnabled;
    final int? effectiveReminderMinutes = reminderMinutesBefore ?? this.reminderMinutesBefore;

    if (effectiveReminderEnabled && effectiveReminderMinutes == null) {
       // If enabling reminder but no minutes provided, maybe default or use existing?
       // For now, let's keep the existing minutes if enabling and none provided.
       // If explicitly setting minutes to null while enabling, that's an issue handled below.
       if (this.reminderMinutesBefore == null) {
         // Or throw error? Let's default to 15 mins for now if enabling without specific time
         // print("Warning: Reminder enabled without minutes, defaulting to 15 minutes before."); // Removed print
         // effectiveReminderMinutes = 15; // Re-enable if default is desired
       }
    }
     if (effectiveReminderEnabled && effectiveReminderMinutes == null && this.reminderMinutesBefore == null) {
        throw ArgumentError('Cannot enable reminder without setting reminderMinutesBefore.');
     }


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
      reminderEnabled: effectiveReminderEnabled,
      // Ensure minutes is null if reminder is disabled
      reminderMinutesBefore: effectiveReminderEnabled ? (effectiveReminderMinutes ?? this.reminderMinutesBefore) : null,
      isPrivate: isPrivate ?? this.isPrivate,
      // Handle new flags in copyWith
      isOccurrence: isOccurrence ?? this.isOccurrence,
      originalEventId: originalEventId ?? this.originalEventId,
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
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      isOccurrence: json['isOccurrence'] as bool? ?? false,
      originalEventId: json['originalEventId'] as String?,
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
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isPrivate': isPrivate,
      'isOccurrence': isOccurrence,
      'originalEventId': originalEventId,
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
        _listEquals(other.resourceIds, resourceIds) &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderMinutesBefore == reminderMinutesBefore &&
        other.isPrivate == isPrivate &&
        other.isOccurrence == isOccurrence && // Add to equality check
        other.originalEventId == originalEventId; // Add to equality check
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
      // Use Object.hashAll for lists within Object.hash
      resourceIds != null ? Object.hashAll(resourceIds!) : null,
      reminderEnabled,
      reminderMinutesBefore,
      reminderEnabled,
      reminderMinutesBefore,
      isPrivate,
      isOccurrence, // Add to hash
      originalEventId, // Add to hash
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
