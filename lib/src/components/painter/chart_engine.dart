import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../utils/time_assistant.dart' as timeAssistant;
import '../view_mode.dart';
import '../translations/translations.dart';

typedef TooltipCallback = void Function({
  DateTimeRange? range,
  double? amount,
  DateTime? amountDate,
  required ScrollPosition position,
  required Rect rect,
  required double barWidth,
});

const int kWeeklyDayCount = 7;
const int kMonthlyDayCount = 31;

const double kYLabelMargin = 12.0;
const int _kPivotYLabelHour = 12;

const double kXLabelHeight = 32.0;

const double kLineStrokeWidth = 0.8;

const double kBarWidthRatio = 0.7;
const double kBarPaddingWidthRatio = (1 - kBarWidthRatio) / 2;

const Color kLineColor1 = Color(0x44757575);
const Color kLineColor2 = Color(0x77757575);
const Color kLineColor3 = Color(0xAA757575);
const Color kTextColor = Color(0xFF757575);

class StartPair {
  StartPair(this.index, this.day);

  final int index;
  final int day;
}

class OffsetRange {
  double dx;
  double topY;
  double bottomY;
  DateTimeRange data;

  OffsetRange(this.dx, this.topY, this.bottomY, this.data);
}

class OffsetWithAmountDate {
  double dx;
  double dy;
  double amount;
  DateTime dateTime;

  OffsetWithAmountDate(this.dx, this.dy, this.amount, this.dateTime);
}

abstract class ChartEngine extends CustomPainter {
  ChartEngine({
    this.scrollController,
    int? dayCount,
    bool isLastDataChanged = false,
    required this.viewMode,
    this.firstValueDateTime,
    required this.context,
  }) : dayCount = math.max(dayCount ?? getViewModeLimitDay(viewMode),
            viewMode == ViewMode.weekly ? kWeeklyDayCount : kMonthlyDayCount) {
    _translations = Translations(context);
  }

  final ScrollController? scrollController;

  /// 요일의 갯수가 [kWeeklyDayCount]이상인 경우만 해당 값이며 나머지 경우는
  /// [kWeeklyDayCount]이다.
  final int dayCount;

  final ViewMode viewMode;

  final DateTime? firstValueDateTime;

  final BuildContext context;

  int get dayOfCurrentScrollView {
    if (!scrollController!.hasClients) return 0;
    return (scrollController!.offset / blockWidth!).round();
  }

  Radius get barRadius => const Radius.circular(6.0);

  /// 전체 그래프의 오른쪽 레이블이 들어갈 간격의 크기이다.
  double get rightMargin => _rightMargin;

  /// 바 너비의 크기이다.
  double get barWidth => _barWidth;

  /// 바를 적절하게 정렬하기 위한 값이다.
  double get paddingForAlignedBar => _paddingForAlignedBar;

  /// (바와 바 사이의 여백의 너비 + 바의 너비) => 블럭 너비의 크기이다.
  double? get blockWidth => _blockWidth;

  Translations? get translations => _translations;

  TextTheme get textTheme => Theme.of(context).textTheme;

  double _rightMargin = 0.0;
  double _barWidth = 0.0;
  double _paddingForAlignedBar = 0.0;
  double? _blockWidth;
  Translations? _translations;

  /// 각 바의 위치와 크기를 생성하는 함수이다.
  List<dynamic> generateCoordinates(Size size);

  /// 그래프의 Y 축 레이블을 그린다.
  void drawYLabels(Canvas canvas, Size size);

  /// 그래프의 바를 그린다.
  void drawBar(Canvas canvas, Size size, List<dynamic> coordinates);

  /// Y 축의 텍스트 레이블을 그린다.
  void drawYText(Canvas canvas, Size size, String text, double y) {
    TextSpan span = TextSpan(
      text: text,
      style: textTheme.bodyText2!.copyWith(color: kTextColor),
    );

    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    tp.paint(
      canvas,
      Offset(
        size.width - _rightMargin + kYLabelMargin,
        y - textTheme.bodyText2!.fontSize! / 2,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);

    List<dynamic> coordinates = generateCoordinates(size);

    drawYLabels(canvas, size);
    drawBar(canvas, size, coordinates);
  }

  void setRightMargin() {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: translations!.formatHourOnly(_kPivotYLabelHour),
        style: textTheme.bodyText2!.copyWith(color: kTextColor),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    _rightMargin = tp.width + kYLabelMargin;
  }

  void setDefaultValue(Size size) {
    setRightMargin();
    _blockWidth = size.width / dayCount;
    _barWidth = blockWidth! * kBarWidthRatio;
    // 바의 위치를 가운데로 정렬하기 위한 [padding]
    _paddingForAlignedBar = blockWidth! * kBarPaddingWidthRatio;
  }

  void drawXLabels(
    Canvas canvas,
    Size size, {
    bool firstDataHasChanged = false,
  }) {
    final viewLimitDay = getViewModeLimitDay(viewMode);
    final weekday = getShortWeekdayList(context);
    final startDay = math.max(dayOfCurrentScrollView - 1, 0);
    DateTime currentDate = firstValueDateTime!.add(Duration(days: -startDay));

    void turnOneBeforeDay() {
      currentDate = currentDate.add(const Duration(days: -1));
    }

    for (int i = startDay; i < dayCount; i++) {
      if (i - startDay > viewLimitDay + 1) break;

      late String text;
      bool isDashed = true;

      switch (viewMode) {
        case ViewMode.weekly:
          text = weekday[currentDate.weekday % 7];
          if (currentDate.weekday == DateTime.sunday) isDashed = false;
          turnOneBeforeDay();
          break;
        case ViewMode.monthly:
          text = currentDate.day.toString();
          turnOneBeforeDay();
          // 월간 보기 모드는 7일에 한 번씩 label 을 표시한다.
          if (i % 7 != (firstDataHasChanged ? 0 : 6)) continue;
      }

      final dx = size.width - (i + 1) * blockWidth!;

      _drawXText(canvas, size, text, dx);
      _drawVerticalDivideLine(canvas, size, dx, isDashed);
    }
  }

  void _drawXText(Canvas canvas, Size size, String text, double dx) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textTheme.bodyText2!.copyWith(color: kTextColor),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final dy = size.height - textPainter.height;
    textPainter.paint(canvas, Offset(dx + paddingForAlignedBar, dy));
  }

  /// 그래프의 수평선을 그린다
  void drawHorizontalLine(Canvas canvas, Size size, double dy) {
    Paint paint = Paint()
      ..color = kLineColor1
      ..strokeCap = StrokeCap.round
      ..strokeWidth = kLineStrokeWidth;

    canvas.drawLine(Offset(0, dy), Offset(size.width - rightMargin, dy), paint);
  }

  /// 분할하는 세로선을 그려준다.
  void _drawVerticalDivideLine(
    Canvas canvas,
    Size size,
    double dx,
    bool isDashed,
  ) {
    Paint paint = Paint()
      ..color = kLineColor3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = kLineStrokeWidth;

    Path path = Path();
    path.moveTo(dx, 0);
    path.lineTo(dx, size.height);

    canvas.drawPath(
      isDashed
          ? dashPath(path,
              dashArray: CircularIntervalList<double>(<double>[2, 2]))
          : path,
      paint,
    );
  }

  // pivot 에서 duration 만큼 이전으로 시간이 흐르면 나오는 시간
  dynamic getClockDiff(var pivot, var duration) {
    var ret = pivot - duration;
    return ret + (ret <= 0 ? 24 : 0);
  }

  StartPair getStartPairFrom(
    List<DateTimeRange> sleepData,
    int dayOfCurrentScroll,
  ) {
    int startDay = 0;
    int startIndex = 0;

    // 스크롤시 바로 그려지지 않고 미리 그리도록 한 칸 여유를 둔다.
    for (int i = startIndex;
        i < dayOfCurrentScroll - 2 && i + 1 < sleepData.length;
        ++i) {
      startIndex++;
      if (!timeAssistant.areSameDate(sleepData[i].end, sleepData[i + 1].end))
        startDay++;
    }

    return StartPair(startIndex, startDay);
  }
}
