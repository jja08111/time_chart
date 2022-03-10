import 'dart:math';

import 'package:flutter/material.dart';
import 'package:touchable/touchable.dart';
import '../../utils/time_assistant.dart';
import '../../view_mode.dart';
import '../chart_engine.dart';

class AmountBarPainter extends ChartEngine<_AmountBarItem> {
  AmountBarPainter({
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
  final int? topHour;
  final int? bottomHour;

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawBar(canvas, size, generateCoordinates(size));
  }

  @override
  void drawBar(Canvas canvas, Size size, List<_AmountBarItem> coordinates) {
    final touchyCanvas = TouchyCanvas(context, canvas,
        scrollController: scrollController,
        scrollDirection: AxisDirection.left);
    final paint = Paint()
      ..color = barColor ?? Theme.of(context).colorScheme.secondary
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int index = 0; index < coordinates.length; index++) {
      final _AmountBarItem offsetWithAmount = coordinates[index];

      final double left = paddingForAlignedBar + offsetWithAmount.dx;
      final double right =
          paddingForAlignedBar + offsetWithAmount.dx + barWidth;
      final double top = offsetWithAmount.dy;
      final double bottom = size.height;

      final rRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, bottom),
        topLeft: barRadius,
        topRight: barRadius,
      );

      callback(_) => tooltipCallback(
            amount: offsetWithAmount.amount,
            amountDate: offsetWithAmount.dateTime,
            position: scrollController!.position,
            rect: rRect.outerRect,
            barWidth: barWidth,
          );

      touchyCanvas.drawRRect(
        rRect,
        paint,
        onTapUp: callback,
        onLongPressStart: callback,
        onLongPressMoveUpdate: callback,
      );
    }
    //if(bottomHour > 0) {
    //  _drawBrokeBarLine(canvas, size);
    //}
  }

  @override
  List<_AmountBarItem> generateCoordinates(Size size) {
    List<_AmountBarItem> coordinates = [];

    if (dataList.isEmpty) return [];

    final double intervalOfBars = size.width / dayCount;
    final int length = dataList.length;
    final int viewLimitDay = getViewModeLimitDay(viewMode);
    final dayFromScrollOffset = getDayFromScrollOffset();
    final DateTime startDateTime = getBarRenderStartDateTime(dataList);
    final int startIndex = dataList.getLowerBound(startDateTime);

    double amountSum = 0;

    for (int index = startIndex; index < length; index++) {
      final int barPosition =
          1 + dataList.first.end.differenceDateInDay(dataList[index].end);

      if (barPosition - dayFromScrollOffset >
          viewLimitDay + ChartEngine.toleranceDay * 2) break;

      amountSum += dataList[index].durationInHours;

      // 날짜가 다르거나 마지막 데이터면 오른쪽으로 한 칸 이동하여 그린다. 그 외에는 계속 sum 한다.
      if (index == length - 1 ||
          dataList[index].end.differenceDateInDay(dataList[index + 1].end) >
              0) {
        final double normalizedTop =
            max(0, amountSum - bottomHour!) / (topHour! - bottomHour!);

        final double dy = size.height - normalizedTop * size.height;
        final double dx = size.width - intervalOfBars * barPosition;

        coordinates.add(_AmountBarItem(dx, dy, amountSum, dataList[index].end));

        amountSum = 0;
      }
    }

    return coordinates;
  }

  @override
  bool shouldRepaint(AmountBarPainter oldDelegate) {
    return oldDelegate.dataList != dataList;
  }

  @override
  void drawYLabels(Canvas canvas, Size size) {}
}

class _AmountBarItem {
  final double dx;
  final double dy;
  final double amount;
  final DateTime dateTime;

  _AmountBarItem(this.dx, this.dy, this.amount, this.dateTime);
}
