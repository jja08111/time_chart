import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class TimeXLabelPainter extends ChartEngine {
  TimeXLabelPainter({
    required ScrollController scrollController,
    required this.scrollOffsetNotifier,
    required BuildContext context,
    required ViewMode viewMode,
    required DateTime firstValueDateTime,
    required int? dayCount,
    required this.firstDataHasChanged,
  }) : super(
          scrollController: scrollController,
          context: context,
          viewMode: viewMode,
          firstValueDateTime: firstValueDateTime,
          dayCount: dayCount,
          repaint: scrollOffsetNotifier,
        );

  final ValueNotifier<double> scrollOffsetNotifier;
  final bool firstDataHasChanged;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawXLabels(canvas, size, firstDataHasChanged: firstDataHasChanged);
  }

  @override
  bool shouldRepaint(covariant TimeXLabelPainter oldDelegate) {
    return true;
  }
}
