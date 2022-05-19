import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'chart_engine.dart';
import '../view_mode.dart';

abstract class BarPainter<T> extends ChartEngine {
  BarPainter({
    required ScrollController scrollController,
    required this.scrollOffsetNotifier,
    required this.tooltipCallback,
    required BuildContext context,
    required this.dataList,
    required this.topHour,
    required this.bottomHour,
    required int? dayCount,
    required ViewMode viewMode,
    this.barColor,
  }) : super(
          scrollController: scrollController,
          dayCount: dayCount,
          viewMode: viewMode,
          firstValueDateTime:
              dataList.isEmpty ? DateTime.now() : dataList.first.end,
          context: context,
          repaint: scrollOffsetNotifier,
        );

  final ValueNotifier<double> scrollOffsetNotifier;
  final TooltipCallback tooltipCallback;
  final Color? barColor;
  final List<DateTimeRange> dataList;
  final int topHour;
  final int bottomHour;

  Radius get barRadius => const Radius.circular(6.0);

  @override
  @nonVirtual
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawBar(canvas, size, generateCoordinates(size));
  }

  void drawBar(Canvas canvas, Size size, List<T> coordinates);

  List<T> generateCoordinates(Size size);

  @protected
  DateTime getBarRenderStartDateTime(List<DateTimeRange> dataList) {
    return dataList.first.end.add(Duration(
      days: -currentDayFromScrollOffset + ChartEngine.toleranceDay,
    ));
  }

  @override
  @nonVirtual
  bool shouldRepaint(BarPainter oldDelegate) {
    return oldDelegate.dataList != dataList;
  }
}
