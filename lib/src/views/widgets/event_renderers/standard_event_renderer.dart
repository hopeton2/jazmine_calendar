import 'package:flutter/material.dart';
import '../../../models/event.dart';
import 'event_renderer.dart';

class StandardEventRenderer implements EventRenderer {
  @override
  Widget buildEventWidget({
    required BuildContext context,
    required Event event,
    required DateTime cellDate,
    required Size availableSpace,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: event.color ?? Colors.blue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        event.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}