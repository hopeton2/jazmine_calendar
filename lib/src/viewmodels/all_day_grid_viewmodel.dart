import 'package:flutter/material.dart';
import 'dart:math'; // For max function
// Removed unused import for AllDayGrid constants

// Define callback type here or import if defined elsewhere
typedef OverflowStateCallback = void Function(
    bool hasOverflow, int hiddenCount, int maxLaneIndex);

/// ViewModel for the AllDayGrid widget.
///
/// Manages the state related to expansion, overflow detection,
/// and height calculation for the all-day event section.
class AllDayGridViewModel extends ChangeNotifier {
  final int maxVisibleAllDayEvents; // Default visible rows before expanding

  // --- State ---
  bool _isExpanded = false;
  int _actualMaxLaneIndex = -1; // Max lane index reported by the layout surface
  bool _overflowDetected = false; // Whether overflow is currently detected
  int _calculatedHiddenCount = 0; // Number of hidden events due to overflow

  // --- Constants for height calculation (defined directly here) ---
  static const double eventHeight = 25.0;
  static const double verticalSpacing = 2.0;
  // Removed buttonRowHeight constant
  static const double topPadding = 5.0;
  static const double bottomPadding = 7.0; // Add bottom padding constant

  AllDayGridViewModel({required this.maxVisibleAllDayEvents})
      : assert(maxVisibleAllDayEvents >= 0);

  // --- Getters for UI ---
  bool get isExpanded => _isExpanded;
  int get hiddenEventCount => _calculatedHiddenCount;

  /// Determines if the "More" button should be shown.
  bool get showMoreButton => !_isExpanded && _overflowDetected;

  /// Determines if the "Collapse" button should be shown.
  bool get showCollapseButton => _isExpanded && _overflowDetected;

  /// Determines if the button container area should be shown.
  /// It's shown only if either the "More" or "Collapse" button is needed.
  bool get showButtonContainer => showMoreButton || showCollapseButton;

  /// Calculates the target height for the event area based on current state.
  double get targetEventAreaHeight {
    final int actualRowCount =
        _actualMaxLaneIndex >= 0 ? _actualMaxLaneIndex + 1 : 0;
    final int rowsToDisplayCollapsed =
        max(1, min(actualRowCount, maxVisibleAllDayEvents));
    final double collapsedEventAreaHeight =
        _calculateEventAreaHeight(rowsToDisplayCollapsed);
    final double expandedEventAreaHeight =
        _calculateEventAreaHeight(actualRowCount > 0 ? actualRowCount : 1);
    return _isExpanded ? expandedEventAreaHeight : collapsedEventAreaHeight;
  }

  /// Calculates the maximum height available for event content (rows + spacing)
  /// when the grid is in its collapsed state. Excludes top/bottom padding.
  /// This is used to determine if an event should be rendered or hidden when collapsed.
  double get collapsedContentHeight {
     if (maxVisibleAllDayEvents <= 0) return 0.0;
     // Height of visible rows + spacing between them
     return (maxVisibleAllDayEvents * eventHeight) + ((maxVisibleAllDayEvents - 1).clamp(0, double.infinity) * verticalSpacing);
  }

  // Removed totalHeight getter - height is now just targetEventAreaHeight

  // --- Actions ---
  void expand() {
    if (!_isExpanded) {
      _isExpanded = true;
      notifyListeners();
    }
  }

  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      notifyListeners();
    }
  }

  /// Callback handler for overflow state changes reported by the EventLayoutSurface.
  void handleOverflowStateChanged(
      bool hasOverflow, int hiddenCount, int maxLaneIndex) {
    // Update the state only if the reported state changes
    if (_actualMaxLaneIndex != maxLaneIndex ||
        _overflowDetected != hasOverflow ||
        _calculatedHiddenCount != hiddenCount) {
      _actualMaxLaneIndex = maxLaneIndex;
      _overflowDetected = hasOverflow;
      _calculatedHiddenCount = hiddenCount;

      // Important: Notify listeners *after* updating state
      // Use addPostFrameCallback if called during build phase, but here it's likely fine
      notifyListeners();
    }
  }

  // --- Private Helpers ---

  /// Calculates height for the event area ONLY based on number of rows.
  double _calculateEventAreaHeight(int numberOfRows) {
    if (numberOfRows <= 0) {
      // If no rows, the minimum height is just the top padding.
      // If no rows, the minimum height includes top and bottom padding.
      return topPadding + bottomPadding;
    }
    // Calculate height based on events and spacing
    // Calculate height based on events, spacing, and top padding.
    final double totalEventsHeight = (numberOfRows * eventHeight) +
        ((numberOfRows - 1).clamp(0, double.infinity) * verticalSpacing);
    // Calculate height based on events, spacing, top padding, and bottom padding.
    return topPadding + totalEventsHeight + bottomPadding;
  }
}
