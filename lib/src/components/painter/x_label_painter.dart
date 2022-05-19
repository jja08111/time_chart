import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:time_chart/src/components/painter/chart_engine.dart';
import 'package:time_chart/src/components/translations/translations.dart';
import 'package:time_chart/src/components/view_mode.dart';

abstract class XLabelPainter extends ChartEngine {
  static const int toleranceDay = 1;

  XLabelPainter({
    required super.viewMode,
    required super.context,
    this.firstDataHasChanged = false,
    required super.dayCount,
    required super.firstValueDateTime,
    required super.repaint,
    required super.scrollController,
  });

  final bool firstDataHasChanged;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size, firstDataHasChanged: firstDataHasChanged);
  }

  void drawXLabels(
    Canvas canvas,
    Size size, {
    bool firstDataHasChanged = false,
  }) {
    final weekday = getShortWeekdayList(context);
    final viewModeLimitDay = getViewModeLimitDay(viewMode);
    final dayFromScrollOffset = currentDayFromScrollOffset - toleranceDay;

    DateTime currentDate =
        firstValueDateTime!.add(Duration(days: -dayFromScrollOffset));

    void turnOneBeforeDay() {
      currentDate = currentDate.add(const Duration(days: -1));
    }

    for (int i = dayFromScrollOffset;
        i <= dayFromScrollOffset + viewModeLimitDay + toleranceDay * 2;
        i++) {
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

  @override
  bool shouldRepaint(covariant XLabelPainter oldDelegate) {
    return true;
  }
}
