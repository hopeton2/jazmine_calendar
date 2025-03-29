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
