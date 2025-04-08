import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
// Potentially import a UUID generator if needed for new events
// import 'package:uuid/uuid.dart';

/// ViewModel for the [CalendarEventEditor] widget.
///
/// Manages the state and business logic for creating or editing a [CalendarEvent].
class CalendarEventEditorViewModel extends ChangeNotifier {
  final CalendarEvent? _initialEvent;
  final Function(CalendarEvent) _onSaveCallback;

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers for text fields
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  // TODO: Add controllers/state for other fields (dates, times, timezone, recurrence, etc.)

  // State variables
  // TODO: Add state variables for non-text fields (e.g., DateTime, TimeZone, bool for allDay)
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isSaving = false;
  bool _isAllDay = false;
  String _selectedTimeZone = 'UTC'; // Default timezone
  bool _reminderEnabled = false;
  int? _reminderMinutesBefore = 15; // Default to 15 minutes if enabled
  String? _selectedRecurrenceType = 'NONE'; // Default to no recurrence
  Color? _selectedColor;
  bool _isPrivate = false;
  // String? _recurrenceRule; // We'll generate a basic one on save for now

  // --- Getters ---
  CalendarEvent? get event => _initialEvent;
  bool get isEditing => _initialEvent != null;
  bool get isSaving => _isSaving;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isAllDay => _isAllDay;
  String get selectedTimeZone => _selectedTimeZone;
  bool get reminderEnabled => _reminderEnabled;
  int? get reminderMinutesBefore => _reminderMinutesBefore;
  String? get selectedRecurrenceType => _selectedRecurrenceType;
  Color? get selectedColor => _selectedColor;
  bool get isPrivate => _isPrivate;
  // TODO: Add getters for other state variables

  CalendarEventEditorViewModel({
    CalendarEvent? event,
    required Function(CalendarEvent) onSave,
  })  : _initialEvent = event,
        _onSaveCallback = onSave {
    _initializeFields();
  }

  void _initializeFields() {
    titleController = TextEditingController(text: _initialEvent?.title ?? '');
    descriptionController = TextEditingController(text: _initialEvent?.description ?? '');
    _startDate = _initialEvent?.start ?? DateTime.now();
    // Adjust initial end date logic slightly for clarity if needed
    _endDate = _initialEvent?.end ?? _startDate.add(const Duration(hours: 1));
    _isAllDay = _initialEvent?.isAllDay ?? false;
    _selectedTimeZone = _initialEvent?.timeZone ?? 'UTC';
    _reminderEnabled = _initialEvent?.reminderEnabled ?? false;
    _reminderMinutesBefore = _initialEvent?.reminderMinutesBefore ?? (_reminderEnabled ? 15 : null); // Default if enabled but no value
    _selectedRecurrenceType = _initialEvent?.recurrenceType ?? 'NONE';
    locationController = TextEditingController(text: _initialEvent?.location ?? '');
    _selectedColor = _initialEvent?.color; // Allow null color
    _isPrivate = _initialEvent?.isPrivate ?? false;
    // _recurrenceRule = _initialEvent?.recurrenceRule; // Don't load rule directly for now
    // TODO: Initialize other state variables based on _initialEvent
  }

  // --- Actions ---

  Future<void> pickStartDate(BuildContext context) async {
    final initialDate = _startDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      // Keep the existing time, only update the date part
      final newStartDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _startDate.hour, // Keep existing hour
        _startDate.minute, // Keep existing minute
      );
      if (_startDate != newStartDate) {
        _startDate = newStartDate;
        // Ensure end date is not before start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1)); // Default duration
        }
        notifyListeners();
      }
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    final initialTime = TimeOfDay.fromDateTime(_startDate);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final newStartDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (_startDate != newStartDate) {
        _startDate = newStartDate;
        // Ensure end date is not before start date
        if (_endDate.isBefore(_startDate)) {
           _endDate = _startDate.add(const Duration(hours: 1));
        }
        notifyListeners();
      }
    }
  }


  Future<void> pickEndDate(BuildContext context) async {
    final initialDate = _endDate;
    // Suggest starting the date picker from the current start date if logical
    final datePickerInitialDate = initialDate.isBefore(_startDate) ? _startDate : initialDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: datePickerInitialDate,
      // Ensure the first selectable date is not before the start date's day
      firstDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      lastDate: DateTime(2101),
    );

     if (selectedDate != null) {
        // Keep the existing time, only update the date part
        final newEndDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          _endDate.hour, // Keep existing hour
          _endDate.minute, // Keep existing minute
        );

        // Basic validation: Ensure end date is not before start date
        if (newEndDate.isBefore(_startDate)) {
           // print("Error: End date cannot be before start date."); // Removed print
           // Optionally show feedback
           return;
        }

        if (_endDate != newEndDate) {
          _endDate = newEndDate;
          notifyListeners();
        }
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    final initialTime = TimeOfDay.fromDateTime(_endDate);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final newEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Basic validation: Ensure end date/time is after start date/time
      if (newEndDate.isBefore(_startDate)) {
         // print("Error: End time cannot be before start time."); // Removed print
         // Optionally show feedback via ScaffoldMessenger if context is available
         // We might need to pass context here or handle feedback differently
         return;
      }

      if (_endDate != newEndDate) {
        _endDate = newEndDate;
        notifyListeners();
      }
    }
  }


  void toggleAllDay(bool? value) {
    if (value != null && _isAllDay != value) {
      _isAllDay = value;
      // Optional: Adjust start/end times when toggling?
      // e.g., set to midnight when isAllDay = true
      // For now, just update the flag. User can adjust dates separately.
      notifyListeners();
    }
  }

  // Simple list of common time zones for the dropdown
  // TODO: Replace with a more comprehensive list or package integration
  final List<String> availableTimeZones = const [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Berlin',
    'Asia/Tokyo',
    'Australia/Sydney',
  ];

  void setTimeZone(String? timeZone) {
    if (timeZone != null && availableTimeZones.contains(timeZone) && _selectedTimeZone != timeZone) {
      _selectedTimeZone = timeZone;
      notifyListeners();
    }
  }

  // Common reminder intervals (in minutes)
  final List<int> availableReminderIntervals = const [5, 10, 15, 30, 60, 120, 1440]; // 1440 = 1 day

  void toggleReminder(bool? value) {
    if (value != null && _reminderEnabled != value) {
      _reminderEnabled = value;
      if (!_reminderEnabled) {
        _reminderMinutesBefore = null; // Clear minutes if reminder is disabled
      } else if (_reminderMinutesBefore == null) {
        _reminderMinutesBefore = 15; // Set default if enabling and no value exists
      }
      notifyListeners();
    }
  }

  void setReminderMinutes(int? minutes) {
    // Allow setting only if reminder is enabled and value is valid
    if (_reminderEnabled && minutes != null && availableReminderIntervals.contains(minutes)) {
       if (_reminderMinutesBefore != minutes) {
         _reminderMinutesBefore = minutes;
         notifyListeners();
       }
    } else if (_reminderEnabled && minutes == null) {
      // Handle case where user might try to clear selection while enabled?
      // Maybe force a default or show validation. For now, ignore null if enabled.
      // print("Cannot set null reminder minutes while reminder is enabled."); // Removed print
    }
  }


  // Basic recurrence types
  // TODO: Localize these display values
  final List<String> availableRecurrenceTypes = const ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];

  void setRecurrenceType(String? type) {
    if (type != null && availableRecurrenceTypes.contains(type) && _selectedRecurrenceType != type) {
      _selectedRecurrenceType = type;
      notifyListeners();
      // TODO: Potentially open a more detailed recurrence editor based on type
    }
  }

  // Basic RRULE generator (Placeholder)
  String? _generateRRule() {
    if (_selectedRecurrenceType == null || _selectedRecurrenceType == 'NONE') {
      return null;
    }
    // WARNING: These are *very* basic examples and don't cover many options.
    // A proper RRULE library is recommended for real-world use.
    switch (_selectedRecurrenceType) {
      case 'DAILY':
        return 'FREQ=DAILY';
      case 'WEEKLY':
        // Defaults to repeating on the same day of the week as the start date
        return 'FREQ=WEEKLY';
      case 'MONTHLY':
        // Defaults to repeating on the same day of the month
        return 'FREQ=MONTHLY';
      case 'YEARLY':
       // Defaults to repeating on the same month and day
        return 'FREQ=YEARLY';
      default:
        return null;
    }
  }


  // Predefined list of colors for selection
  // TODO: Make this configurable or use a proper color picker
  final List<Color> availableColors = const [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.grey,
  ];

  void setColor(Color? color) {
    // Allow setting null to clear color
    if (_selectedColor != color) {
      _selectedColor = color;
      notifyListeners();
    }
  }

   void togglePrivate(bool? value) {
    if (value != null && _isPrivate != value) {
      _isPrivate = value;
      notifyListeners();
    }
  }


  Future<void> saveEvent() async {
    if (formKey.currentState?.validate() ?? false) {
      _isSaving = true;
      notifyListeners();

      try {
        // Simulate network delay or processing
        await Future.delayed(const Duration(milliseconds: 500));

        // TODO: Gather all data from controllers and state variables
        final eventToSave = CalendarEvent(
          id: _initialEvent?.id ?? UniqueKey().toString(), // Use a proper ID generation strategy
          title: titleController.text,
          description: descriptionController.text,
          start: _startDate,
          end: _endDate,
          isAllDay: _isAllDay,
          timeZone: _selectedTimeZone,
          reminderEnabled: _reminderEnabled,
          reminderMinutesBefore: _reminderEnabled ? _reminderMinutesBefore : null, // Ensure null if disabled
          recurrenceType: _selectedRecurrenceType == 'NONE' ? null : _selectedRecurrenceType,
          recurrenceRule: _generateRRule(), // Generate basic rule on save
          location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
          color: _selectedColor,
          isPrivate: _isPrivate,
          // TODO: Populate other fields (timezone, recurrence, color, etc.)
        );

        _onSaveCallback(eventToSave);
        // Optionally navigate back or show success message - handled by the caller

      } catch (e) {
        // TODO: Implement proper error handling (e.g., show a snackbar)
        // print("Error saving event: $e"); // Removed print
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    } else {
      // print("Form validation failed."); // Removed print
      // Optionally trigger UI feedback for validation errors
    }
  }

  // --- Cleanup ---

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    // TODO: Dispose other controllers
    super.dispose();
  }
}