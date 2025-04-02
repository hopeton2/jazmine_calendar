import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/services/time_calculation_service.dart';

void main() {
  group('DayViewTimeCalculationService', () {
    late DayViewTimeCalculationService service;
    late DateTime viewStart;
    late DateTime viewEnd;
    late Size availableSpace;
    
    setUp(() {
      service = DayViewTimeCalculationService();
      viewStart = DateTime(2023, 1, 1); // Midnight
      viewEnd = DateTime(2023, 1, 2); // Next day midnight
      availableSpace = const Size(800, 1200); // 1200 pixels height
    });
    
    test('calculateTimePosition returns correct position for midnight', () {
      final time = DateTime(2023, 1, 1, 0, 0); // Midnight
      final position = service.calculateTimePosition(time, viewStart, viewEnd, availableSpace);
      expect(position, 0); // Should be at the top
    });
    
    test('calculateTimePosition returns correct position for 6 AM', () {
      final time = DateTime(2023, 1, 1, 6, 0); // 6 AM
      final position = service.calculateTimePosition(time, viewStart, viewEnd, availableSpace);
      
      // 6 hours = 6/24 of the height = 0.25 * 1200 = 300
      expect(position, 300);
    });
    
    test('calculateTimePosition returns correct position for noon', () {
      final time = DateTime(2023, 1, 1, 12, 0); // Noon
      final position = service.calculateTimePosition(time, viewStart, viewEnd, availableSpace);
      
      // 12 hours = 12/24 of the height = 0.5 * 1200 = 600
      expect(position, 600);
    });
    
    test('calculateTimePosition returns correct position for 6 PM', () {
      final time = DateTime(2023, 1, 1, 18, 0); // 6 PM
      final position = service.calculateTimePosition(time, viewStart, viewEnd, availableSpace);
      
      // 18 hours = 18/24 of the height = 0.75 * 1200 = 900
      expect(position, 900);
    });
    
    test('calculateTimePosition handles minutes correctly', () {
      final time = DateTime(2023, 1, 1, 10, 30); // 10:30 AM
      final position = service.calculateTimePosition(time, viewStart, viewEnd, availableSpace);
      
      // 10.5 hours = 10.5/24 of the height = 0.4375 * 1200 = 525
      expect(position, 525);
    });
    
    test('calculateSizeForDuration returns correct size for 1 hour', () {
      final duration = const Duration(hours: 1);
      final size = service.calculateSizeForDuration(duration, viewStart, viewEnd, availableSpace);
      
      // 1 hour = 1/24 of the height = 0.0416... * 1200 = 50
      expect(size, 50);
    });
    
    test('calculateSizeForDuration returns correct size for 2 hours', () {
      final duration = const Duration(hours: 2);
      final size = service.calculateSizeForDuration(duration, viewStart, viewEnd, availableSpace);
      
      // 2 hours = 2/24 of the height = 0.0833... * 1200 = 100
      expect(size, 100);
    });
  });
}
