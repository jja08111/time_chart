import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountYLabelPainter extends ChartEngine {
  AmountYLabelPainter({
    @required BuildContext context,
    @required ViewMode viewMode,
    @required this.topHour,
    @required this.bottomHour,
  }) : super(
          context: context,
          viewMode: viewMode,
        );

  final int topHour;
  final int bottomHour;

  @override
  void paint(Canvas canvas, Size size) {
    setRightMargin();
    drawYLabels(canvas, size);
  }

  // Y축 텍스트(레이블)을 그림. 최저값과 최고값을 Y축에 표시함.
  @override
  void drawYLabels(Canvas canvas, Size size) {
    final hourSuffix = translations.shortHour;
    final double interval =
        (size.height - kXLabelHeight) / (topHour - bottomHour);
    double posY = 0;

    for (int time = topHour; time >= bottomHour; --time) {
      drawYText(canvas, size,
          time == bottomHour ? '0 $hourSuffix' : '$time $hourSuffix', posY);
      if (topHour > time && time > bottomHour)
        drawHorizontalLine(canvas, size, posY);

      posY += interval;
    }
  }

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}

  @override
  List generateCoordinates(Size size) => [];

  @override
  bool shouldRepaint(covariant AmountYLabelPainter oldDelegate) {
    return oldDelegate.topHour != this.topHour ||
        oldDelegate.bottomHour != this.bottomHour;
  }
}
