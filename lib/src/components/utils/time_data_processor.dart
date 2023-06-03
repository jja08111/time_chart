import 'dart:math';

import 'package:flutter/material.dart';
import 'package:time_chart/src/components/painter/chart_engine.dart';
import '../../../time_chart.dart';
import '../../chart.dart';
import 'time_assistant.dart' as time_assistant;

/// 0
const double _kMinHour = 0.0;

/// 24
const double _kMaxHour = 24.0;

const String _kNotSortedDataErrorMessage =
    'The data list is reversed or not sorted. Check the data parameter. The first data must be newest data.';

/// 데이터를 적절히 가공하는 믹스인이다.
///
/// 이 믹스인은 [topHour]와 [bottomHour] 등을 계산하기 위해 사용한다.
///
/// 위의 두 기준 시간을 구하는 알고리즘은 다음과 같다.
/// 1. 주어진 데이터들에서 현재 차트에 표시되어야 하는 데이터만 고른다. 즉, 차트의 오른쪽 시간과 왼쪽 시간에
///    포함되는 데이터만 고른다. 이때 좌, 우로 하루씩 허용오차를 두어 차트가 잘못 그려지는 것을 방지한다.
/// 2. 선택된 데이터를 이용하여 기준 값들을 먼저 구해본다. 기준 값은 데이터에서 가장 공백이 큰 시간 범위를
///    찾아 반환한다.
/// 3. 구해진 기준 값 중 [bottomHour]과 24시 사이에 있는 데이터들에 각각 하루 씩 더한다.
///
/// 위와 같은 과정을 지나면 [_processedData]에는 기준 시간에 맞게 수정된 데이터들이 들어있다.
mixin TimeDataProcessor {
  static const Duration _oneDayDuration = Duration(days: 1);

  /// 현재 [Chart]의 상태에 맞게 가공된 데이터를 반환한다.
  ///
  /// [bottomHour]와 24시 사이에 있는 데이터들을 다음날로 넘어가 있다.
  List<DateTimeRange> get processedData => _processedData;
  List<DateTimeRange> _processedData = [];

  final List<DateTimeRange> _inRangeDataList = [];

  int? get topHour => _topHour;
  int? _topHour;

  int? get bottomHour => _bottomHour;
  int? _bottomHour;

  int? get dayCount => _dayCount;
  int? _dayCount;

  /// 첫 데이터가 [bottomHour]와 24시(정확히는 0시) 사이에 존재하여 다음 칸에 그려져야 하는
  /// 경우 `true`이다.
  bool get isFirstDataMovedNextDay => _isFirstDataMovedNextDay;
  bool _isFirstDataMovedNextDay = false;

  void processData(Chart chart, DateTime renderEndTime) {
    if (chart.data.isEmpty) {
      _handleEmptyData(chart);
      return;
    }
    // print("preprocessing i0: ${chart.data[0].runtimeType}");
    _processedData = [...chart.data];
    _isFirstDataMovedNextDay = false;

    _countDays(chart.data);
    _generateInRangeDataList(chart.data, chart.viewMode, renderEndTime);
    switch (chart.chartType) {
      case ChartType.time:
        _setPivotHours(chart.defaultPivotHour);
        _processDataUsingBottomHour();
        break;
      case ChartType.amount:
        _calcAmountPivotHeights(chart.data);
        break;
    }
    // print("postprocessing i0: ${_processedData[0].runtimeType}");
  }

  void _handleEmptyData(Chart chart) {
    switch (chart.chartType) {
      case ChartType.time:
        _topHour = chart.defaultPivotHour;
        _bottomHour = _topHour! + 8;
        break;
      case ChartType.amount:
        _topHour = 8;
        _bottomHour = 0;
    }
    _dayCount = 0;
  }

  void _setPivotHours(int defaultPivotHour) {
    final timePair = _getPivotHoursFrom(_inRangeDataList);
    if (timePair == null) return;
    final startTime = timePair.startTime;
    final endTime = timePair.endTime;

    // 아래와 같이 범위가 형성된 경우는 따로 고려한다.
    // |##|
    // |##| -> endTime (ex: 8h 0m)
    //
    // |##| -> startTime (ex: 8h 40m)
    // |##|
    if (startTime.floor() == endTime.floor() && endTime < startTime) {
      _topHour = startTime.floor();
      _bottomHour = startTime.floor();
      return;
    }

    _topHour = startTime.floor();
    _bottomHour = endTime.ceil();
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

  void _countDays(List<DateTimeRange> dataList) {
    assert(dataList.isNotEmpty);

    final firstDateTime = dataList.first.end;
    final lastDateTime = dataList.last.end;

    if (dataList.length > 1) {
      assert(firstDateTime.isAfter(lastDateTime), _kNotSortedDataErrorMessage);
    }
    _dayCount = firstDateTime.differenceDateInDay(lastDateTime) + 1;
  }

  /// 입력으로 들어온 [dataList]에서 [renderEndTime]부터 [viewMode]의 제한 일수 기간 동안 포함된
  /// [_inRangeDataList]를 만든다.
  void _generateInRangeDataList(
    List<DateTimeRange> dataList,
    ViewMode viewMode,
    DateTime renderEndTime,
  ) {
    renderEndTime = renderEndTime.add(
      const Duration(days: ChartEngine.toleranceDay),
    );
    final renderStartTime = renderEndTime.add(Duration(
      days: -viewMode.dayCount - 2 * ChartEngine.toleranceDay,
    ));

    _inRangeDataList.clear();

    DateTime postEndTime =
        dataList.first.end.add(_oneDayDuration).dateWithoutTime();
    for (int i = 0; i < dataList.length; ++i) {
      if (i > 0) {
        assert(
          dataList[i - 1].end.isAfter(dataList[i].end),
          _kNotSortedDataErrorMessage,
        );
      }
      final currentTime = dataList[i].end.dateWithoutTime();
      // 이전 데이터와 날짜가 다른 경우
      if (currentTime != postEndTime) {
        final difference = postEndTime.differenceDateInDay(currentTime);
        // 하루 이상 차이나는 경우
        postEndTime = postEndTime.add(Duration(days: -difference));
      }
      postEndTime = currentTime;

      if (renderStartTime.isBefore(currentTime) &&
          currentTime.isBefore(renderEndTime)) {
        _inRangeDataList.add(dataList[i]);
      }
    }
  }

  /// [bottomHour]과 24시(정확히는 0시) 사이에 [timeDouble]이 위치한 경우 `true`를 반환한다.
  ///
  /// 구체적으로 [timeDouble] 시간이 차트에서 다음 칸에 위치해야 하는 경우를 말한다.
  bool _isNextCellPosition(double timeDouble) {
    // 제일 아래의 시간이 0시인 경우 해당 블럭은 무조건 해당 시간으로 표시하여야 한다.
    if (bottomHour == 0) return false;
    return bottomHour! < timeDouble;
  }

  /// 데이터의 시작 시간과 종료 시간 모두 [bottomHour]와 24시 사이에 존재하는 경우 해당 데이터를
  /// 다음날로 가공한다.
  ///
  /// 만약 다음날로 가공하지 않는다면 다음 칸에 그려져야 할 데이터가 동일한 칸에 그려질 수 있다. 다음 칸에
  /// 그려져야 할 데이터란 날짜는 같지만 차트에서 위치상으로만 다음 칸인 데이터의 경우를 말하는 것이다.
  ///
  /// 예를 들어 차트가 20시부터 8시까지를 그리도록 데이터가 주어졌다고 가정하자. 이때 데이터 중 하나가
  /// 21시 ~ 23시라면 0시를 기준으로 다음날로 넘어가기 때문에 해당 데이터를 다음 칸에 그려야 한다.
  void _processDataUsingBottomHour() {
    final len = _processedData.length;
    for (int i = 0; i < len; ++i) {
      final DateTime startTime = _processedData[i].start;
      final DateTime endTime = _processedData[i].end;
      final double startTimeDouble = startTime.toDouble();
      final double endTimeDouble = endTime.toDouble();

      if (_isNextCellPosition(startTimeDouble) &&
          _isNextCellPosition(endTimeDouble)) {
        _processedData[i] = _processedData[i].copy(
          start: startTime.add(_oneDayDuration),
          end: endTime.add(_oneDayDuration),
        );

        if (i == 0) {
          _dayCount = _dayCount! + 1;
          _isFirstDataMovedNextDay = true;
        }
      }
    }
  }

  /// 시간 그래프의 기준이 될 값들을 구한다.
  ///
  /// 시간 데이터가 비어 있는 구간 중 가장 넓은 부분이 선택되며, 선택된 값의 시작 시간이
  /// [topHour], 종료 시간이 [bottomHour]가 된다.
  _TimePair? _getPivotHoursFrom(List<DateTimeRange> dataList) {
    final List<_TimePair> rangeList = _getSortedRangeListFrom(dataList);
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
    return resultPair;
  }

  /// [double] 형식으로 24시간에 시간 데이터 리스트가 어떻게 분포되어있는지 구간 리스트를 반환한다.
  ///
  /// 이 값들은 오름차순으로 정렬되어 있다.
  List<_TimePair> _getSortedRangeListFrom(List<DateTimeRange> dataList) {
    List<_TimePair> rangeList = [];

    for (int i = 0; i < dataList.length; ++i) {
      final curSleepPair =
          _TimePair(dataList[i].start.toDouble(), dataList[i].end.toDouble());

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
  List<_TimePair> _mergeRange(_TimePair timePair, List<_TimePair> rangeList) {
    int loIdx = -1;
    int hiIdx = -1;

    // 먼저 [sleepPair]의 안에 포함되는 목록을 제거한다.
    for (int i = 0; i < rangeList.length; ++i) {
      final curPair = rangeList[i];
      if (timePair.inRange(curPair.startTime) &&
          timePair.inRange(curPair.endTime)) rangeList.removeAt(i--);
    }

    for (int i = 0; i < rangeList.length; ++i) {
      final _TimePair curSleepPair =
          _TimePair(rangeList[i].startTime, rangeList[i].endTime);

      if (loIdx == -1 && curSleepPair.inRange(timePair.startTime)) {
        loIdx = i;
      }
      if (hiIdx == -1 && curSleepPair.inRange(timePair.endTime)) {
        hiIdx = i;
      }
      if (loIdx != -1 && hiIdx != -1) {
        break;
      }
    }

    final newSleepPair = _TimePair(
        loIdx == -1 ? timePair.startTime : rangeList[loIdx].startTime,
        hiIdx == -1 ? timePair.endTime : rangeList[hiIdx].endTime);

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

  void _calcAmountPivotHeights(List<DateTimeRange> dataList) {
    final int len = dataList.length;

    double maxResult = 0.0;
    double sum = 0.0;

    for (int i = 0; i < len; ++i) {
      final amount = dataList[i].durationInHours;
      sum += amount;

      if (i == len - 1 ||
          dataList[i].end.dateWithoutTime() !=
              dataList[i + 1].end.dateWithoutTime()) {
        maxResult = max(maxResult, sum);
        sum = 0.0;
      }
    }

    // `_topHour`는 4의 배수가 되도록 한다.
    _topHour = ((maxResult.ceil()) / 4).ceil() * 4;
    _bottomHour = 0;
  }

  /// [b]에서 [a]로 흐른 시간을 구한다. 예를 들어 5시에서 3시로 흐른 시간은 22시간이고,
  /// 16시에서 19시로 흐른 시간은 3시간이다.
  ///
  /// 이를 역으로 이용하여 끝 시간으로부터 시작 시간을 구할 수 있다.
  /// [b]에 총 시간 크기를 넣고 [a]에 끝 시간을 넣으면 시작 시간이 반환된다.
  dynamic hourDiffBetween(dynamic a, dynamic b) {
    final c = b - a;
    if (c <= 0) return 24.0 + c;
    return c;
  }
}

class _TimePair implements Comparable {
  /// [double] 타입으로 이루어진 시작 시간과 끝 시간을 가진 클래스를 생성한다.
  const _TimePair(this._startTime, this._endTime);

  final double _startTime;
  final double _endTime;

  double get startTime => _startTime;

  double get endTime => _endTime;

  bool inRange(double a) => _startTime <= a && a <= _endTime;

  @override
  int compareTo(other) {
    if (_startTime < other.startTime) return -1;
    if (_startTime > other.startTime) return 1;
    return 0;
  }

  @override
  String toString() => 'startTime: $startTime, wakeUp: $endTime';
}
