import 'package:flutter/material.dart';

class DateTimeRangeWithColor extends DateTimeRange {
  DateTimeRangeWithColor(
      {required super.start, required super.end, required this.color});

  final Color color;

  @override
  DateTime get end => DateTimeWithColor.fromDateTime(super.end, color);

  factory DateTimeRangeWithColor.fromDateTimeRange(
      DateTimeRange dtr, Color color) {
    return DateTimeRangeWithColor(start: dtr.start, end: dtr.end, color: color);
  }

  //overrides extension so a warning is given
  @override
  DateTimeRangeWithColor copy({DateTime? start, DateTime? end, Color? color}) =>
      DateTimeRangeWithColor(
          start: start ?? this.start,
          end: end ?? this.end,
          color: color ?? this.color);
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
    return DateTimeWithColor(color, dt.year, dt.month, dt.day, dt.hour,
        dt.minute, dt.second, dt.millisecond, dt.microsecond);
  }
}

extension Copy on DateTimeRange {
  DateTimeRange copy({DateTime? start, DateTime? end, Color? color}) =>
      DateTimeRange(start: start ?? this.start, end: end ?? this.end);
}
