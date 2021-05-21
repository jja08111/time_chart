import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountXLabelPainter extends ChartEngine {
  AmountXLabelPainter({
    required ScrollController scrollController,
    required this.scrollOffset,
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
        );

  final double scrollOffset;
  
  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size);
  }

  @override
  List generateCoordinates(Size size) => [];

  @override
  void drawYLabels(Canvas canvas, Size size) {}

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}

  @override
  bool shouldRepaint(covariant AmountXLabelPainter oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset;
  }
}
