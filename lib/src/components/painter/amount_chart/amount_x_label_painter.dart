
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountXLabelPainter extends ChartEngine {
  AmountXLabelPainter({
    @required BuildContext context,
    @required ViewMode viewMode,
    @required DateTime firstValueDateTime,
    @required int dayCount,
    @required this.inFadeAnimating,
  }) : super(
    context: context,
    viewMode: viewMode,
    firstValueDateTime: firstValueDateTime,
    dayCount: dayCount,
  );

  final bool inFadeAnimating;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size, inFadeAnimating: inFadeAnimating);
  }

  @override
  bool shouldRepaint(covariant AmountXLabelPainter oldDelegate) {
    return oldDelegate.inFadeAnimating != inFadeAnimating;
  }

  @override
  List generateCoordinates(Size size) => [];

  @override
  void drawYLabels(Canvas canvas, Size size) {}

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}
}