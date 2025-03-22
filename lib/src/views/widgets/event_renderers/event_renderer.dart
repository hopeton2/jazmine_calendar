import 'package:flutter/material.dart';
import '../../../models/event.dart';

abstract class EventRenderer {
  Widget buildEventWidget({
    required BuildContext context,
    required Event event,
    required DateTime cellDate,
    required Size availableSpace,
  });
}