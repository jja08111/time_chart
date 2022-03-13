import 'dart:math';

import 'package:flutter/material.dart';

/// 지난달이 몇달인지 구한다.
int getPreviousMonthFrom(int month) {
  if (month == 1) return 12;
  return month - 1;
}

/// [a]시에서 [b]시로 흐른 시간을 구한다.
int diffBetween(int a, int b) {
  final result = b - a;

  if (result < 0) return 24 + result;
  return result;
}

/// 이전 기준 시간들(top: [beforeTop], bottom: [beforeBottom])에 현재 기준
/// 시간들(top: [top], bottom: [bottom])을 이용하여 Animation 방향을 얻는다.
///
/// 위쪽이면 true, 아래쪽이면 false 를 반환한다.
bool isDirUpward(int beforeTop, int beforeBottom, int top, int bottom) {
  if (beforeBottom <= beforeTop) beforeBottom += 24;
  if (bottom <= top) bottom += 24;

  void goFront() {
    top += 24;
    bottom += 24;
  }

  void goBack() {
    top -= 24;
    bottom -= 24;
  }

  // 뒤에서부터 앞으로 이동하며 많이 겹치는 구간을 찾기 위해 가장 뒤로 이동한다.
  while (bottom > beforeTop) {
    goBack();
  }
  goFront();

  int upward = 0, downward = 0;
  while (beforeBottom > top) {
    if (beforeTop < top) {
      upward = max(upward, min(bottom - top, beforeBottom - top));
    } else {
      downward = max(downward, min(bottom - top, bottom - beforeTop));
    }
    //print('before: $beforeTop, $beforeBottom, will: $top, $bottom');
    //print('up: $upward, down: $downward');
    goFront();
  }
  //print('------------------------------');
  return upward > downward;
}

/// [range]안에 [hour]가 포함되면 `true`를 반환한다.
bool isInRangeHour(DateTimeRange range, int hour) {
  DateTime time =
      DateTime(range.start.year, range.start.month, range.start.day, hour);
  // 두 시간 사이에 위치 할 수 있도록 한다.
  if (time.isBefore(range.start)) time = time.add(const Duration(days: 1));

  if (range.start.isBefore(time) && time.isBefore(range.end)) return true;
  return false;
}

extension DateTimeUtils on DateTime {
  /// Return `true` if [other] has same date without time.
  bool isSameDateWith(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Return day that date difference with [other].
  int differenceDateInDay(DateTime other) {
    DateTime thisDate = dateWithoutTime();
    DateTime otherDate = other.dateWithoutTime();

    return thisDate.difference(otherDate).inDays;
  }

  DateTime dateWithoutTime() {
    return DateTime(year, month, day);
  }

  double toDouble() {
    return hour.toDouble() + minute.toDouble() / 60;
  }
}

extension DateTimeRangeUtils on DateTimeRange {
  double get durationInHours {
    return duration.inMinutes / 60;
  }
}

extension DateTimeRangeListUtils on List<DateTimeRange> {
  /// 이진 탐색을 하며 [targetDate] 날짜를 초과하며 가장 최근의 날짜를 가진 데이터의 인덱스를 반환한다.
  ///
  /// 이것을 호출 할때 리스트의 값들은 첫 번째 인덱스가 늦은 날짜인 순으로 정렬되어 있어야 한다.
  int getLowerBound(DateTime targetDate) {
    int min = 0;
    int max = length;
    int result = -1;

    while (min < max) {
      result = min + ((max - min) >> 1);
      final DateTimeRange element = this[result];
      final int comp = targetDate.differenceDateInDay(element.end);
      if (comp == 0) {
        break;
      }
      if (comp < 0) {
        min = result + 1;
      } else {
        max = result;
      }
    }
    // 같은 날 중에 가장 최근 날짜 데이터로 고른다.
    while (
        result - 1 >= 0 && this[result - 1].end.day == this[result].end.day) {
      result--;
    }
    return result;
  }
}
