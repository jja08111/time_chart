import 'dart:math';

import 'package:flutter/material.dart';
import 'package:time_chart/src/components/painter/bar_painter.dart';
import 'package:touchable/touchable.dart';
import '../../utils/time_assistant.dart';
import '../chart_engine.dart';

class AmountBarPainter extends BarPainter<AmountBarItem> {
  AmountBarPainter({
    required super.scrollController,
    required super.repaint,
    required super.tooltipCallback,
    required super.context,
    required super.dataList,
    required super.topHour,
    required super.bottomHour,
    required super.dayCount,
    required super.viewMode,
    super.barColor,
  });

  @override
  void drawBar(Canvas canvas, Size size, List<AmountBarItem> coordinates) {
    final touchyCanvas = TouchyCanvas(context, canvas,
        scrollController: scrollController,
        scrollDirection: AxisDirection.left);
    final paint = Paint()
      ..color = barColor ?? Theme.of(context).colorScheme.secondary
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int index = 0; index < coordinates.length; index++) {
      final AmountBarItem offsetWithAmount = coordinates[index];

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
  List<AmountBarItem> generateCoordinates(Size size) {
    final List<AmountBarItem> coordinates = [];

    if (dataList.isEmpty) return [];

    final double intervalOfBars = size.width / dayCount;
    final int length = dataList.length;
    final int viewLimitDay = viewMode.dayCount;
    final dayFromScrollOffset = currentDayFromScrollOffset;
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
            max(0, amountSum - bottomHour) / (topHour - bottomHour);

        final double dy = size.height - normalizedTop * size.height;
        final double dx = size.width - intervalOfBars * barPosition;

        coordinates.add(AmountBarItem(dx, dy, amountSum, dataList[index].end));

        amountSum = 0;
      }
    }

    return coordinates;
  }
}

class AmountBarItem {
  final double dx;
  final double dy;
  final double amount;
  final DateTime dateTime;

  AmountBarItem(this.dx, this.dy, this.amount, this.dateTime);
}
