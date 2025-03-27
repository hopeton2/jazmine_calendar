extension DateTimeExtensions on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get firstDayOfMonth => DateTime(year, month, 1);

  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  List<DateTime> getDaysInWeek() {
    return List.generate(7, (index) => add(Duration(days: index)));
  }

  List<DateTime> getDaysInWorkWeek() {
    return List.generate(5, (index) => add(Duration(days: index)));
  }

  List<DateTime> getDaysInMonth() {
    final first = firstDayOfMonth;
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = first.weekday;
    final weeksCount = ((daysInMonth + firstWeekday - 1) / 7).ceil();

    return List.generate(weeksCount * 7, (index) {
      final dayNumber = index - firstWeekday + 2;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }
      return DateTime(year, month, dayNumber);
    }).where((date) => date != null).cast<DateTime>().toList();
  }

  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  bool isWithinRange(DateTime start, DateTime end) {
    return (isAfter(start) || isSameDay(start)) &&
        (isBefore(end) || isSameDay(end));
  }

  /// Calculates the start date of the week containing this date based on the specified first day of week.
  DateTime getWeekStartDate(int firstDayOfWeek) {
    final weekday = this.weekday;
    
    int daysToSubtract;
    if (weekday > firstDayOfWeek) {
      daysToSubtract = weekday - firstDayOfWeek;
    } else if (weekday < firstDayOfWeek) {
      daysToSubtract = 7 - (firstDayOfWeek - weekday);
    } else {
      daysToSubtract = 0;
    }
    
    return subtract(Duration(days: daysToSubtract));
  }

  bool isEventInDay(DateTime eventStart, DateTime eventEnd) {
    final date = DateTime(year, month, day);
    return date.isAfter(eventStart.subtract(const Duration(days: 1))) &&
        date.isBefore(eventEnd.add(const Duration(days: 1)));
  }

  DateTime get firstDayOfQuarter {
    final quarterMonth = ((month - 1) ~/ 3) * 3 + 1;
    return DateTime(year, quarterMonth, 1);
  }

  DateTime get lastDayOfQuarter {
    final quarterMonth = ((month - 1) ~/ 3) * 3 + 3;
    return DateTime(year, quarterMonth + 1, 0);
  }

  DateTime get nextQuarter {
    final currentQuarter = ((month - 1) ~/ 3);
    final nextQuarterFirstMonth = (currentQuarter + 1) * 3 + 1;
    final nextYear = nextQuarterFirstMonth > 12 ? year + 1 : year;
    final nextMonth = nextQuarterFirstMonth > 12 ? 1 : nextQuarterFirstMonth;
    return DateTime(nextYear, nextMonth, 1);
  }

  DateTime get previousQuarter {
    final currentQuarter = ((month - 1) ~/ 3);
    final prevQuarterFirstMonth = currentQuarter * 3 - 2;
    final prevYear = prevQuarterFirstMonth < 1 ? year - 1 : year;
    final prevMonth = prevQuarterFirstMonth < 1 ? 10 : prevQuarterFirstMonth;
    return DateTime(prevYear, prevMonth, 1);
  }

  DateTime get nextYear => DateTime(year + 1, 1, 1);

  DateTime get previousYear => DateTime(year - 1, 1, 1);

  DateTime get firstDayOfYear => DateTime(year, 1, 1);

  DateTime get lastDayOfYear => DateTime(year, 12, 31);

  Duration durationUntil(DateTime end) => end.difference(this);

  DateTime getWeekStartDateOfDay(bool startOnSunday) {
    final weekday = this.weekday;
    final firstDayOfWeek = startOnSunday ? DateTime.sunday : DateTime.monday;
    final diff = weekday - firstDayOfWeek;
    return subtract(Duration(days: diff < 0 ? diff + 7 : diff));
  }

  /// Returns the week number of the year for this date
  int get weekNumber => (difference(firstDayOfYear).inDays / 7).ceil();
}

extension DurationExtensions on Duration {
  /// Returns true if the duration equals Duration.zero
  bool get isZero => this == Duration.zero;
}
