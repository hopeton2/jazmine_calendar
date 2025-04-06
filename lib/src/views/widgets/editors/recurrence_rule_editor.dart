import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart'; // Import for potential use later
// TODO: Import localization if needed

// Placeholder for returning the result
class RecurrenceRuleResult {
  final String? rruleString;
  final String? frequencyType; // e.g., 'DAILY', 'WEEKLY'

  RecurrenceRuleResult({this.rruleString, this.frequencyType});
}

class RecurrenceRuleEditor extends StatefulWidget {
  final String? initialRRuleString; // Pass the current rule
  final DateTime eventStartDate; // Needed for context (e.g., weekly on which day)

  const RecurrenceRuleEditor({
    super.key,
    this.initialRRuleString,
    required this.eventStartDate,
  });

  @override
  State<RecurrenceRuleEditor> createState() => _RecurrenceRuleEditorState();
}

class _RecurrenceRuleEditorState extends State<RecurrenceRuleEditor> {
  // --- State Variables ---
  // TODO: Add state for frequency, interval, weekdays, month days, end condition etc.
  String _selectedFrequency = 'NONE'; // Example: NONE, DAILY, WEEKLY, MONTHLY, YEARLY
  int _interval = 1;
  Set<int> _selectedWeekdays = {}; // Example: {DateTime.monday, DateTime.tuesday}
  // TODO: Add state for monthly options (day of month, day of week)
  // TODO: Add state for end condition (never, count, until date)
  DateTime? _endDate;
  int? _count;

  @override
  void initState() {
    super.initState();
    _parseInitialRule();
  }

  void _parseInitialRule() {
    // TODO: Implement parsing logic using rrule package or manually
    // to populate the initial state based on widget.initialRRuleString
    if (widget.initialRRuleString != null) {
      try {
        // Example parsing (needs refinement with rrule package)
        final rrule = RecurrenceRule.fromString(widget.initialRRuleString!);
        _selectedFrequency = rrule.frequency.toString().split('.').last; // Extract frequency name
        _interval = rrule.interval ?? 1; // Default to 1 if null
        // ... parse other parts like BYDAY, UNTIL, COUNT ...
        _endDate = rrule.until;
        _count = rrule.count;
        if (rrule.byWeekDays.isNotEmpty) {
           _selectedWeekdays = rrule.byWeekDays.map((entry) => entry.day).toSet();
        }

      } catch (e) {
        print("Error parsing initial RRULE: ${widget.initialRRuleString} - $e");
        // Reset to default if parsing fails
        _selectedFrequency = 'NONE';
        _interval = 1;
        _selectedWeekdays = {};
        _endDate = null;
        _count = null;
      }
    } else {
       _selectedFrequency = 'NONE';
    }
     // Ensure initial state consistency
     if (_selectedFrequency == 'NONE') {
        _interval = 1;
        _selectedWeekdays = {};
        _endDate = null;
        _count = null;
     }
  }

  void _saveAndClose() {
    // TODO: Implement logic to build the RRULE string based on current state
    String? finalRRuleString;
    String? finalFrequencyType = _selectedFrequency;

    if (_selectedFrequency != 'NONE') {
       // Example RRULE building (needs refinement with rrule package)
       try {
          // Map frequency string to Frequency enum
          final freq = _mapStringToFrequency(_selectedFrequency);
          if (freq == null) throw Exception("Invalid frequency selected"); // Should not happen with dropdown
          final rrule = RecurrenceRule(
             frequency: freq,
             interval: _interval,
             until: _endDate,
             count: _count,
             byWeekDays: _selectedWeekdays.map((day) => ByWeekDayEntry(day)).toList(), // Use toList()
             // ... add other parameters based on state ...
             // dtstart is typically not part of the RRULE string itself,
             // but is used when generating instances. Remove from constructor.
          );
          finalRRuleString = rrule.toString();
       } catch (e) {
          print("Error building RRULE: $e");
          finalRRuleString = null; // Don't save invalid rule
          finalFrequencyType = 'NONE';
       }
    } else {
       finalRRuleString = null; // No rule if frequency is NONE
    }


    Navigator.pop(
      context,
      RecurrenceRuleResult(
        rruleString: finalRRuleString,
        frequencyType: finalFrequencyType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Build the actual UI with dropdowns, checkboxes, date pickers etc.
    return Scaffold( // Wrap in Scaffold if presented as a page
      appBar: AppBar(
        title: const Text('Edit Recurrence'), // TODO: Localize
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndClose,
            tooltip: 'Save', // TODO: Localize
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // --- Frequency Dropdown ---
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              items: ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'] // TODO: Localize display names
                  .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                    // Reset dependent fields when frequency changes
                    _interval = 1;
                    _selectedWeekdays = {};
                    _endDate = null;
                    _count = null;
                    // TODO: Reset monthly options
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Frequency'), // TODO: Localize
            ),
            const SizedBox(height: 16),

            // --- Interval Field (if not NONE) ---
            if (_selectedFrequency != 'NONE')
              TextFormField(
                initialValue: _interval.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Repeat every'), // TODO: Localize + add unit (days, weeks etc)
                onChanged: (value) {
                  setState(() {
                    _interval = int.tryParse(value) ?? 1;
                    if (_interval < 1) _interval = 1; // Ensure interval is positive
                  });
                },
              ),
            const SizedBox(height: 16),

            // --- Weekly Options ---
            if (_selectedFrequency == 'WEEKLY')
              _buildWeekdaySelector(),
            const SizedBox(height: 16),

            // --- Monthly Options (Placeholder) ---
            if (_selectedFrequency == 'MONTHLY')
              const Text('Monthly options UI (TBD)'), // TODO: Implement monthly UI
            const SizedBox(height: 16),

            // --- Yearly Options (Placeholder) ---
             if (_selectedFrequency == 'YEARLY')
              const Text('Yearly options UI (TBD)'), // TODO: Implement yearly UI
            const SizedBox(height: 16),

            // --- End Condition ---
             if (_selectedFrequency != 'NONE')
               _buildEndConditionSelector(),

            // TODO: Add more UI elements based on selected frequency
          ],
        ),
      ),
    );
  }

  // Helper for weekday selection
  Widget _buildWeekdaySelector() {
     final weekdays = [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday];
     // TODO: Use localized weekday names/order based on locale/firstDayOfWeek
     final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

     return Wrap(
        spacing: 8.0,
        children: List.generate(weekdays.length, (index) {
           final day = weekdays[index];
           final isSelected = _selectedWeekdays.contains(day);
           return FilterChip(
              label: Text(weekdayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                 setState(() {
                    if (selected) {
                       _selectedWeekdays.add(day);
                    } else {
                       _selectedWeekdays.remove(day);
                    }
                 });
              },
           );
        }),
     );
  }

   // Helper for end condition selection
   Widget _buildEndConditionSelector() {
      // TODO: Implement UI for Never, Count, Until Date
      return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text("Ends", style: Theme.of(context).textTheme.titleMedium), // TODO: Localize
            // Placeholder - Needs proper radio buttons, text fields, date picker
            RadioListTile(title: Text("Never"), value: "NEVER", groupValue: _getEndConditionType(), onChanged: _setEndCondition),
            RadioListTile(title: Text("After occurrences"), value: "COUNT", groupValue: _getEndConditionType(), onChanged: _setEndCondition),
             if (_count != null) TextFormField(initialValue: _count.toString(), /* ... */ ),
            RadioListTile(title: Text("On date"), value: "UNTIL", groupValue: _getEndConditionType(), onChanged: _setEndCondition),
             if (_endDate != null) ListTile(title: Text("Date: ${_endDate!.toLocal()}"), onTap: _pickEndDate), // TODO: Format date
         ],
      );
   }

   String _getEndConditionType() {
      if (_count != null) return "COUNT";
      if (_endDate != null) return "UNTIL";
      return "NEVER";
   }

   void _setEndCondition(String? value) {
      setState(() {
         if (value == "NEVER") {
            _count = null;
            _endDate = null;
         } else if (value == "COUNT") {
            _count = _count ?? 10; // Default count
            _endDate = null;
         } else if (value == "UNTIL") {
            _count = null;
            _endDate = _endDate ?? DateTime.now().add(const Duration(days: 30)); // Default date
         }
      });
   }

   Future<void> _pickEndDate() async {
      final picked = await showDatePicker(
         context: context,
         initialDate: _endDate ?? DateTime.now(),
         firstDate: widget.eventStartDate, // Cannot end before it starts
         lastDate: DateTime(2101),
      );
      if (picked != null && picked != _endDate) {
         setState(() {
            _endDate = picked;
         });
      }
   }

   // Helper to map frequency string to enum
   Frequency? _mapStringToFrequency(String freqString) {
     switch (freqString) {
       case 'DAILY': return Frequency.daily;
       case 'WEEKLY': return Frequency.weekly;
       case 'MONTHLY': return Frequency.monthly;
       case 'YEARLY': return Frequency.yearly;
       default: return null; // Or handle NONE case if needed
     }
   }

}