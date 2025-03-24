

import 'dart:async';

import 'package:flutter/widgets.dart';

class TimeService {
  final ValueNotifier<DateTime> currentTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<Duration> intervalNotifier;
  Timer? _timer;

  TimeService({Duration interval = const Duration(minutes: 30)})
      : intervalNotifier = ValueNotifier(interval) {
    _startTimer();
  }

  void _startTimer() {
    currentTimeNotifier.value = DateTime.now();
    
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final delay = nextMinute.difference(now);

    Timer(delay, () {
      currentTimeNotifier.value = DateTime.now();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        currentTimeNotifier.value = DateTime.now();
      });
    });
  }

  void setInterval(Duration interval) {
    intervalNotifier.value = interval;
  }

  void dispose() {
    _timer?.cancel();
    currentTimeNotifier.dispose();
    intervalNotifier.dispose();
  }
}