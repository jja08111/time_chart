import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class TimeXLabelPainter extends ChartEngine {
  TimeXLabelPainter({
    required BuildContext context,
    required ViewMode viewMode,
    required DateTime firstValueDateTime,
    required int? dayCount,
    required this.firstDataHasChanged,
    required this.inFadeAnimating,
  }) : super(
          context: context,
          viewMode: viewMode,
          firstValueDateTime: firstValueDateTime,
          dayCount: dayCount,
        );

  final bool firstDataHasChanged;
  final bool inFadeAnimating;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size,
        inFadeAnimating: inFadeAnimating,
        firstDataHasChanged: firstDataHasChanged);
  }

  @override
  bool shouldRepaint(covariant TimeXLabelPainter oldDelegate) {
    return oldDelegate.inFadeAnimating != inFadeAnimating;
  }

  @override
  List generateCoordinates(Size size) => [];

  @override
  void drawYLabels(Canvas canvas, Size size) {}

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}
}
