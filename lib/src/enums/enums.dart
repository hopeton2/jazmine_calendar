enum CalendarViewType {
  day,
  workWeek,
  week,
  month,
  agenda,
  timeline,
}

enum TimelineInterval {
  week,
  month,
  quarter,
  year;

  Duration? get duration {
    return switch (this) {
      TimelineInterval.week => const Duration(days: 7),
      TimelineInterval.month => null, // Variable length
      TimelineInterval.quarter => null, // Variable length
      TimelineInterval.year => null, // Variable length
    };
  }
}

enum NavigationBarStyle {
  standard, // Current two-row layout
  compact, // New single-row layout
}

/// Enum representing different event spanning modes for packing
enum EventSpanningMode {
  /// Span only into columns that are completely empty during the event's time.
  strict,

  /// Span into adjacent columns if the specific event doesn't collide,
  /// allowing visual overlap with other non-colliding events in that column.
  compact,
}

/// Enum representing the handles used for resizing events
enum ResizeHandle {
  top,
  bottom,
  left,
  right,
}
