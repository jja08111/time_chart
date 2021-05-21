import 'dart:math';

import 'package:flutter/material.dart';

bool areSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime dateWithoutTime(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

double dateTimeToDouble(DateTime time) {
  return time.hour.toDouble() + time.minute.toDouble() / 60;
}

/// 지난달이 몇달인지 구한다.
int getLastMonthFrom(int month) {
  if (month == 1) return 12;
  return month - 1;
}

/// 두 날짜 사이에 한 날이 비는 경우 true, 붙은 날짜인 경우 false 반환
///
/// a가 나중에 발생한 시간이다.
bool hasEmptyDayBetween(DateTime a, DateTime b) {
  DateTime after = a, before = b;
  if (a.isBefore(b)) {
    after = b;
    before = a;
  }
  if (after.day == before.add(const Duration(days: 2)).day) return true;
  return false;
}

double durationHour(DateTimeRange range) {
  return range.duration.inMinutes / 60;
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
  while (bottom > beforeTop) goBack();
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
