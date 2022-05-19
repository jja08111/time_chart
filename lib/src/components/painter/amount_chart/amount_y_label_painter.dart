import 'package:flutter/material.dart';
import 'package:time_chart/src/components/painter/y_label_painter.dart';

import '../chart_engine.dart';

class AmountYLabelPainter extends YLabelPainter {
  AmountYLabelPainter({
    required super.context,
    required super.viewMode,
    required super.topHour,
    required super.bottomHour,
  });

  @override
  void drawYLabels(Canvas canvas, Size size) {
    final hourSuffix = translations!.shortHour;
    final double interval =
        (size.height - kXLabelHeight) / (topHour - bottomHour);
    double posY = 0;

    for (int time = topHour; time >= bottomHour; --time) {
      drawYText(canvas, size,
          time == bottomHour ? '0 $hourSuffix' : '$time $hourSuffix', posY);
      if (topHour > time && time > bottomHour) {
        drawHorizontalLine(canvas, size, posY);
      }

      posY += interval;
    }
  }
}
