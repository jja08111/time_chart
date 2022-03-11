import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountXLabelPainter extends ChartEngine {
  AmountXLabelPainter({
    required ScrollController scrollController,
    required this.scrollOffsetNotifier,
    required BuildContext context,
    required ViewMode viewMode,
    required DateTime firstValueDateTime,
    required int? dayCount,
  }) : super(
          scrollController: scrollController,
          context: context,
          viewMode: viewMode,
          firstValueDateTime: firstValueDateTime,
          dayCount: dayCount,
          repaint: scrollOffsetNotifier,
        );

  final ValueNotifier<double> scrollOffsetNotifier;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size);
  }

  @override
  bool shouldRepaint(covariant AmountXLabelPainter oldDelegate) {
    return true;
  }
}
