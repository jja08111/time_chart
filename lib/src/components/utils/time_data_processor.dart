import 'dart:math';

import 'package:flutter/material.dart';
import '../view_mode.dart';
import '../../time_chart.dart';
import 'time_assistant.dart' as TimeAssistant;

/// 0
const double _kMinHour = 0.0;

/// 24
const double _kMaxHour = 24.0;

/// 데이터를 적절히 가공하는 클래스이다.
///
/// 이 클래스는 빈 날짜를 수면량이 0인 데이터로 채우고 [topHour]와 [bottomHour]를
/// 계산한다.
abstract class TimeDataProcessor {
  static const Duration _onePostDayDuration = const Duration(days: 1);
  static const Duration _oneBeforeDayDuration = const Duration(days: -1);

  // TODO: 사용자가 커스텀 가능하도록 수정
  /// This is used when the time chart has no data or the time range is fully visible.
  static const int defaultPivotHour = 18;

  List<DateTimeRange> _processedSleepData = [];

  List<DateTimeRange> get processedSleepData => _processedSleepData;

  List<DateTimeRange> _pivotList = [];

  int? _topHour;

  int? get topHour => _topHour;

  int? _bottomHour;

  int? get bottomHour => _bottomHour;

  int? _dayCount;

  int? get dayCount => _dayCount;

  /// 첫 데이터가 다음날로 넘겨진 경우 true 이다.
  ///
  /// 이때 [dayCount]가 7 이상이어야 한다.
  bool _firstDataHasChanged = false;

  bool get firstDataHasChanged => _firstDataHasChanged;

  void processData(List<DateTimeRange> sleepData, ViewMode viewMode,
      ChartType chartType, DateTime pivotEnd) {
    _initProcessData(sleepData, viewMode, pivotEnd);
    switch (chartType) {
      case ChartType.time:
        _generatePivotHours();
        _secondProcessData();
        // 가공 후 다시 기준 값을 구한다.
        _generatePivotHours();
        break;
      case ChartType.amount:
        _calcAmountPivotHeights(sleepData);
    }
  }

  void _generatePivotHours() {
    final sleepPair = _getPivotHours(_pivotList);
    if (sleepPair == null) return;
    final sleepTime = sleepPair.startTime;
    final wakeUp = sleepPair.endTime;
    // 아래와 같이 범위가 형성된 경우를 고려한다.
    // |##|
    // |##| -> wakeUp
    //
    // |##| -> sleepTime
    // |##|
    if (sleepTime.floor() == wakeUp.floor() && wakeUp < sleepTime) {
      _topHour = sleepTime.floor();
      _bottomHour = sleepTime.floor();
      return;
    }
    _topHour = sleepTime.floor();
    _bottomHour = wakeUp.ceil();
    if (_topHour! % 2 != _bottomHour! % 2) {
      _topHour = hourDiffBetween(1, _topHour).toInt();
    }
    _topHour = _topHour! % 24;
    _bottomHour = _bottomHour! % 24;
    // use default pivot hour if there are no space or the time range is fully visible
    if (_topHour == _bottomHour) {
      _topHour = defaultPivotHour;
      _bottomHour = defaultPivotHour;
    }
  }

  void _fillEmptyDay() {
    for (int i = 0; i < _processedSleepData.length; ++i) {
      // 이미 [initProcessData]에서 빈 공간을 채워 넣었기 때문에 현재 발생한 빈 공간은
      // 2칸을 넘을 수 없다.
      final beforeEndTime = _processedSleepData[i].end;
      if (i > 0 &&
          TimeAssistant.hasEmptyDayBetween(
              _processedSleepData[i - 1].end, beforeEndTime)) {
        final postDate = beforeEndTime.add(_onePostDayDuration);
        _processedSleepData.insert(
            i, DateTimeRange(start: postDate, end: postDate));
        ++i;
      }
    }
  }

  bool _isNextDayTime(double timeDouble) {
    return bottomHour! < timeDouble && timeDouble < 24.0;
  }

  void _increaseDayCount() {
    _dayCount = _dayCount! + 1;
  }

  /// 수면 시간이 [bottomHour]과 24시 사이에 존재하는 경우 해당 데이터를 다음날로 가공한다.
  void _secondProcessData() {
    final len = _processedSleepData.length;
    for (int i = 0; i < len; ++i) {
      final DateTime sleepTime = _processedSleepData[i].start;
      final DateTime wakeUpTime = _processedSleepData[i].end;
      final double sleepTimeDouble = TimeAssistant.dateTimeToDouble(sleepTime);
      final double wakeUpTimeDouble =
          TimeAssistant.dateTimeToDouble(wakeUpTime);

      if (sleepTimeDouble < wakeUpTimeDouble &&
          _isNextDayTime(sleepTimeDouble) &&
          _isNextDayTime(wakeUpTimeDouble)) {
        _processedSleepData.removeAt(i);
        _processedSleepData.insert(
          i,
          DateTimeRange(
            start: sleepTime.add(_onePostDayDuration),
            end: wakeUpTime.add(_onePostDayDuration),
          ),
        );

        if (i == 0) {
          _increaseDayCount();
          _firstDataHasChanged = true;
        } // 7일 전부 채워진 상태에서 마지막 날이 다음 칸으로 넘어간 경우

      }
    }
    _fillEmptyDay();
  }

  /// 첫 입력으로 들어온 데이터를 이용 가능하게 초기 가공해준다.
  ///
  /// 이때 데이터에서 빈 날짜를 0인 수면량으로 채우고 데이터 타입에 맞게 데이터 길이를
  /// 맞춘다. 예를 들어 [ViewMode.weekly]인 경우는 길이가 7이고 [ViewMode.monthly]인
  /// 경우는 길이가 31로 제한하여 가공한다.
  void _initProcessData(
      List<DateTimeRange> sleepData, ViewMode viewMode, DateTime pivotHi) {
    final pivotLo =
        pivotHi.add(Duration(days: -getViewModeLimitDay(viewMode) - 2));

    _processedSleepData.clear();
    _pivotList.clear();
    _dayCount = 0;
    _firstDataHasChanged = false;

    DateTime postEndTime = TimeAssistant.dateWithoutTime(
        sleepData.first.end.add(_onePostDayDuration));
    for (int i = 0; i < sleepData.length; ++i) {
      if (i > 0) {
        assert(sleepData[i - 1].end.isAfter(sleepData[i].end),
            'The data list is reversed or not sorted. Check the data parameter. The first data must be oldest data.');
      }
      final currentTime = TimeAssistant.dateWithoutTime(sleepData[i].end);
      // 이전 데이터와 날짜가 다른 경우
      if (currentTime != postEndTime) {
        _increaseDayCount();
        // 하루 이상 차이나는 경우
        while (currentTime != postEndTime.add(_oneBeforeDayDuration)) {
          postEndTime = postEndTime.add(_oneBeforeDayDuration);
          // 빈 데이터를 넣는다.
          _processedSleepData
              .add(DateTimeRange(start: postEndTime, end: postEndTime));
          _increaseDayCount();
        }
      }
      postEndTime = currentTime;
      _processedSleepData.add(sleepData[i]);

      if (pivotLo.isBefore(currentTime) && currentTime.isBefore(pivotHi)) {
        _pivotList.add(sleepData[i]);
      }
    }
  }

  /// 수면 그래프의 기준이 될 값들을 구한다.
  ///
  /// 수면하지 않은 구간이 가장 넓은 부분이 선택되며, 선택된 값의 취침 시간이
  /// [topHour], 기상 시간이 [bottomHour]가 된다.
  _TimePair? _getPivotHours(List<DateTimeRange> sleepData) {
    final List<_TimePair> rangeList = _getSortedRangeListFrom(sleepData);
    if (rangeList.isEmpty) return null;

    // 빈 공간 중 범위가 가장 넓은 부분을 찾는다.
    final len = rangeList.length;
    _TimePair resultPair =
        _TimePair(rangeList[0].startTime, rangeList[0].endTime);
    double maxInterval = 0.0;

    for (int i = 0; i < len; ++i) {
      final lo = i, hi = (i + 1) % len;
      final wakeUp = rangeList[lo].endTime;
      final sleepTime = rangeList[hi].startTime;

      double interval = sleepTime - wakeUp;
      if (interval < 0) {
        interval += 24;
      }

      if (maxInterval < interval) {
        maxInterval = interval;
        resultPair = _TimePair(sleepTime, wakeUp);
      }
    }
    //print(resultPair);
    return resultPair;
  }

  /// [sleepAmountList]과 [wakeUpTimeList]를 이용하여 수면한 범위들을 구한다.
  /// 이 값들은 오름차순으로 정렬되어 있다.
  List<_TimePair> _getSortedRangeListFrom(List<DateTimeRange> sleepData) {
    List<_TimePair> rangeList = [];

    for (int i = 0; i < sleepData.length; ++i) {
      final curSleepPair = _TimePair(
          TimeAssistant.dateTimeToDouble(sleepData[i].start),
          TimeAssistant.dateTimeToDouble(sleepData[i].end));

      // 23시 ~ 6시와 같은 0시를 사이에 둔 경우 0시를 기준으로 두 범위로 나눈다.
      if (curSleepPair.startTime > curSleepPair.endTime) {
        final frontPair = _TimePair(_kMinHour, curSleepPair.endTime);
        final backPair = _TimePair(curSleepPair.startTime, _kMaxHour);

        rangeList = _mergeRange(frontPair, rangeList);
        rangeList = _mergeRange(backPair, rangeList);
      } else {
        rangeList = _mergeRange(curSleepPair, rangeList);
      }
    }
    // 오름차순으로 정렬한다.
    rangeList.sort((a, b) => a.compareTo(b));
    return rangeList;
  }

  /// [hour]이 [rangeList]에 포함되는 리스트가 있는 경우 해당 리스트와 병합하여
  /// [rangeList]를 반환한다.
  ///
  /// 항상 [rangeList]의 값들 중 서로 겹쳐지는 값은 존재하지 않는다.
  List<_TimePair> _mergeRange(_TimePair sleepPair, List<_TimePair> rangeList) {
    int loIdx = -1;
    int hiIdx = -1;

    // 먼저 [sleepPair]의 안에 포함되는 목록을 제거한다.
    for (int i = 0; i < rangeList.length; ++i) {
      final curPair = rangeList[i];
      if (sleepPair.inRange(curPair.startTime) &&
          sleepPair.inRange(curPair.endTime)) rangeList.removeAt(i--);
    }

    for (int i = 0; i < rangeList.length; ++i) {
      final _TimePair curSleepPair =
          _TimePair(rangeList[i].startTime, rangeList[i].endTime);

      if (loIdx == -1 && curSleepPair.inRange(sleepPair.startTime)) {
        loIdx = i;
      }
      if (hiIdx == -1 && curSleepPair.inRange(sleepPair.endTime)) {
        hiIdx = i;
      }
      if (loIdx != -1 && hiIdx != -1) {
        break;
      }
    }

    final newSleepPair = _TimePair(
        loIdx == -1 ? sleepPair.startTime : rangeList[loIdx].startTime,
        hiIdx == -1 ? sleepPair.endTime : rangeList[hiIdx].endTime);

    // 겹치는 부분을 제거한다.
    // 1. 이미 존재하는 것에 완전히 포함되는 경우
    if (loIdx != -1 && loIdx == hiIdx) {
      rangeList.removeAt(loIdx);
    } // 각 다른 것에 겹치는 경우
    else {
      if (loIdx != -1) {
        rangeList.removeAt(loIdx);
        if (loIdx < hiIdx) --hiIdx;
      }
      if (hiIdx != -1) rangeList.removeAt(hiIdx);
    }

    for (int i = 0; i < rangeList.length; ++i) {
      final curSleepPair = rangeList[i];
      if (newSleepPair.inRange(curSleepPair.startTime) &&
          newSleepPair.inRange(curSleepPair.endTime)) {
        rangeList.remove(curSleepPair);
      }
    }

    rangeList.add(newSleepPair);
    return rangeList;
  }

  void _calcAmountPivotHeights(List<DateTimeRange> sleepData) {
    final double infinity = 10000.0;
    final int len = sleepData.length;

    double maxResult = 0.0;
    double minResult = infinity;
    double sum = 0.0;

    for (int i = 0; i < len; ++i) {
      final amount = TimeAssistant.durationHour(sleepData[i]);
      sum += amount;

      if (i == len - 1 ||
          TimeAssistant.dateWithoutTime(sleepData[i].end) !=
              TimeAssistant.dateWithoutTime(sleepData[i + 1].end)) {
        maxResult = max(maxResult, sum);
        if (sum > 0.0) {
          minResult = min(minResult, sum);
        }
        sum = 0.0;
      }
    }

    _topHour = maxResult.ceil();
    _bottomHour = minResult == infinity ? 0 : max(0, minResult.floor() - 1);
  }

  /// [b]에서 [a]로 흐른 시간을 구한다. 예를 들어 5시에서 3시로 흐른 시간은 22시간이고,
  /// 16시에서 19시로 흐른 시간은 3시간이다.
  ///
  /// 이를 역으로 이용하여 기상시간에서 취침시간을 구할 수 있다.
  /// [b]에 수면량을 넣고 [a]에 기상 시간을 넣으면 취침시간이 반환된다.
  dynamic hourDiffBetween(dynamic a, dynamic b) {
    final c = b - a;
    if (c <= 0) return 24.0 + c;
    return c;
  }
}

class _TimePair implements Comparable {
  /// 정수로 이루어진 수면 시작 시간과 기상시간을 가진 클래스를 생성한다.
  const _TimePair(this._startTime, this._endTime);

  final double _startTime;
  final double _endTime;

  double get startTime => _startTime;

  double get endTime => _endTime;

  bool inRange(double a) => _startTime <= a && a <= _endTime;

  @override
  int compareTo(other) {
    if (this._startTime < other.startTime) return -1;
    if (this._startTime > other.startTime) return 1;
    return 0;
  }

  @override
  String toString() => 'startTime: $startTime, wakeUp: $endTime';
}
