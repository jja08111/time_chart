import 'package:flutter/material.dart';

class DateTimeRangeWithColor extends DateTimeRange {
  DateTimeRangeWithColor(
      {required super.start, required super.end, required this.color});

  final Color color;

  factory DateTimeRangeWithColor.fromDateTimeRange(
      DateTimeRange dtr, Color color) {
    return DateTimeRangeWithColor(start: dtr.start, end: dtr.end, color: color);
  }
}

class DateTimeWithColor extends DateTime {
  DateTimeWithColor(this.color, super.year,
      [super.month,
      super.day,
      super.hour,
      super.minute,
      super.second,
      super.millisecond,
      super.microsecond]);

  final Color color;

  factory DateTimeWithColor.fromDateTime(DateTime dt, Color color) {
    return DateTimeWithColor(color, dt.month, dt.hour, dt.minute, dt.second,
        dt.millisecond, dt.microsecond);
  }
}
