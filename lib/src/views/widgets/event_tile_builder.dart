import 'package:flutter/material.dart';
import '../../models/event.dart';

class EventTileBuilder {
  Widget buildEventTile(BuildContext context, Event event) {
    return ListTile(
      title: Text(event.title),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}