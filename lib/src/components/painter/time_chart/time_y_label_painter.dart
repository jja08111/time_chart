
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class TimeYLabelPainter extends ChartEngine {
  TimeYLabelPainter({
    @required BuildContext context,
    @required ViewMode viewMode,
    @required this.topHour,
    @required this.bottomHour
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

  @override
  void drawYLabels(Canvas canvas, Size size) {
    final double bottomY = size.height - kXLabelHeight;
    // 맨 위부터 2시간 단위로 시간을 그린다.
    final double gabY = bottomY / (getClockDiff(bottomHour, topHour)) * 2;

    // 모든 구간이 꽉 차서 모든 범위가 표시되어야 하는 경우 true 이다.
    bool sameTopBottomHour = topHour == (bottomHour % 24);
    int time = topHour;
    double posY = 0;

    // 2칸 간격으로 좌측 레이블 표시
    while(true) {
      drawYText(canvas, size, translations.formatHourOnly(time), posY);
      // 맨 아래에 도달한 경우
      if(time == bottomHour % 24) {
        if(sameTopBottomHour)
          sameTopBottomHour = false;
        else
          break;
      }
      if(posY > 0)
        drawHorizontalLine(canvas, size, posY);

      time = (time + 2) % 24;
      posY += gabY;
    }
  }

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}

  @override
  List generateCoordinates(Size size) => [];

  @override
  bool shouldRepaint(covariant TimeYLabelPainter oldDelegate) {
    return oldDelegate.topHour != this.topHour
        || oldDelegate.bottomHour != this.bottomHour;
  }
}