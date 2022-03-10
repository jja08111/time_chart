import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/components/utils/time_assistant.dart';

void main() {
  group('DateTimeRangeListUtils.getLowerBound', () {
    final List<DateTimeRange> dateTimeList = [];
    final startDateTime = DateTime(2021, 1, 1, 0, 0);
    final random = Random();
    const count = 1000;
    // The list must be in descending order.
    for (int i = count; i >= 0; --i) {
      final hour = random.nextInt(3);
      final minute = random.nextInt(60);
      dateTimeList.add(
        DateTimeRange(
          start: startDateTime.add(
            Duration(days: i, hours: hour, minutes: minute),
          ),
          end: startDateTime.add(
            Duration(days: i, hours: hour + 8, minutes: minute),
          ),
        ),
      );
    }

    test('returns correct index if input is in range', () {
      expect(
        dateTimeList.getLowerBound(startDateTime),
        count,
      );
      expect(
        dateTimeList.getLowerBound(startDateTime.add(const Duration(days: 3))),
        count - 3,
      );
      expect(
        dateTimeList
            .getLowerBound(startDateTime.add(const Duration(days: 500))),
        count - 500,
      );
      expect(
        dateTimeList
            .getLowerBound(startDateTime.add(const Duration(days: 777))),
        count - 777,
      );
      expect(
        dateTimeList.getLowerBound(
          startDateTime.add(const Duration(days: count)),
        ),
        0,
      );
    });

    test('returns 0 if input is exceeded of range', () {
      expect(
        dateTimeList.getLowerBound(
          startDateTime.add(const Duration(days: count + 1)),
        ),
        0,
      );
    });

    test('returns length of list if input is lower of range', () {
      expect(
        dateTimeList.getLowerBound(startDateTime.add(const Duration(days: -1))),
        count,
      );
    });

    test('returns -1 if list is empty', () {
      expect(<DateTimeRange>[].getLowerBound(startDateTime), -1);
    });
  });
}
