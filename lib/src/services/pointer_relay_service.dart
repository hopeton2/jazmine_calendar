import 'dart:async';
import 'package:flutter/gestures.dart';

/// A singleton service to relay pointer events.
///
/// This allows decoupling the source of pointer events (e.g., a Listener covering
/// the grid) from the consumers (e.g., an overlay surface that needs to react
/// to events hitting specific elements within it).
class PointerRelayService {
  // Private constructor
  PointerRelayService._internal();

  // Singleton instance
  static final PointerRelayService _instance = PointerRelayService._internal();

  // Static getter for the instance
  static PointerRelayService get instance => _instance;

  // Stream controller for broadcasting pointer events
  // Using broadcast so multiple listeners (if ever needed) can subscribe.
  final StreamController<PointerEvent> _pointerEventController =
      StreamController<PointerEvent>.broadcast();

  /// Stream of pointer events published by the service.
  Stream<PointerEvent> get events => _pointerEventController.stream;

  /// Publishes a pointer event to all listeners.
  void publish(PointerEvent event) {
    if (!_pointerEventController.isClosed) {
      _pointerEventController.add(event);
    }
  }

  /// Closes the pointer event stream.
  /// Should be called when the application is disposed, though as a singleton,
  /// its lifecycle is often tied to the app's lifecycle.
  void dispose() {
    _pointerEventController.close();
  }
}