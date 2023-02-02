import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:time_chart/src/components/painter/chart_engine.dart';

abstract class YLabelPainter extends ChartEngine {
  YLabelPainter({
    required super.viewMode,
    required super.context,
    required this.topHour,
    required this.bottomHour,
  });

  final int topHour;
  final int bottomHour;

  @override
  @nonVirtual
  void paint(Canvas canvas, Size size) {
    setRightMargin();
    drawYLabels(canvas, size);
  }

  void drawYLabels(Canvas canvas, Size size);

  /// Y 축의 텍스트 레이블을 그린다.
  void drawYText(Canvas canvas, Size size, String text, double y) {
    TextSpan span = TextSpan(
      text: text,
      style: textTheme.bodyMedium!.copyWith(color: kTextColor),
    );

    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    tp.paint(
      canvas,
      Offset(
        size.width - rightMargin + kYLabelMargin,
        y - textTheme.bodyMedium!.fontSize! / 2,
      ),
    );
  }

  /// 그래프의 수평선을 그린다
  void drawHorizontalLine(Canvas canvas, Size size, double dy) {
    Paint paint = Paint()
      ..color = kLineColor1
      ..strokeCap = StrokeCap.round
      ..strokeWidth = kLineStrokeWidth;

    canvas.drawLine(Offset(0, dy), Offset(size.width - rightMargin, dy), paint);
  }

  @override
  bool shouldRepaint(covariant YLabelPainter oldDelegate) {
    return oldDelegate.topHour != topHour ||
        oldDelegate.bottomHour != bottomHour;
  }
}
