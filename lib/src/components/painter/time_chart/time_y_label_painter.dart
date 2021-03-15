import 'dart:ui';
import 'package:flutter/material.dart';

import '../../view_mode.dart';
import '../chart_engine.dart';

class TimeYLabelPainter extends ChartEngine {
  TimeYLabelPainter({
    @required BuildContext context,
    @required ViewMode viewMode,
    @required this.topHour,
    @required this.bottomHour,
    @required this.chartHeight,
    @required this.topPosition,
  }) : super(
          context: context,
          viewMode: viewMode,
        );

  final int topHour;
  final int bottomHour;
  final double chartHeight;

  /// 애니메이션시 위쪽이 얼마나 벗어났는지를 이용하여 추가적인 레이블을 그리거나
  /// 그리지 않기 위한 값이다.
  ///
  /// 음수인 경우 위로 벗어난 것이고 양수인 경우 아래로 이동한 것이다.
  final double topPosition;

  @override
  void paint(Canvas canvas, Size size) {
    setRightMargin();
    drawYLabels(canvas, size);
  }

  static const double _tolerance = 6.0;

  bool visible(double posY, {bool onTolerance = false}) {
    final actualPosY = posY + topPosition;
    final tolerance = onTolerance ? _tolerance : 0;
    return -tolerance <= actualPosY &&
        actualPosY <= chartHeight - kXLabelHeight + tolerance;
  }

  void _drawLabelAndLine(Canvas canvas, Size size, double posY, int time) {
    if (visible(posY)) drawHorizontalLine(canvas, size, posY);
    if (visible(posY, onTolerance: true))
      drawYText(canvas, size, translations.formatHourOnly(time), posY);
  }

  @override
  void drawYLabels(Canvas canvas, Size size) {
    final double bottomY = size.height - kXLabelHeight;
    // 맨 위부터 2시간 단위로 시간을 그린다.
    final double gabY = bottomY / (getClockDiff(bottomHour, topHour)) * 2;

    // 모든 구간이 꽉 차서 모든 범위가 표시되어야 하는 경우 true 이다.
    bool sameTopBottomHour = topHour == (bottomHour % 24);
    int time = topHour;
    double posY = 0.0;

    // 애니메이션시 상단 부분 레이블과 라인이 비지 않도록 그려준다.
    while (-topPosition <= posY) {
      if ((time -= 2) < 0) time += 24;
      posY -= gabY;
      _drawLabelAndLine(canvas, size, posY, time);
    }
    time = topHour;
    posY = 0.0;

    // 2칸 간격으로 좌측 레이블 표시
    while (true) {
      _drawLabelAndLine(canvas, size, posY, time);

      // 맨 아래에 도달한 경우
      if (time == bottomHour % 24) {
        if (sameTopBottomHour)
          sameTopBottomHour = false;
        else
          break;
      }

      time = (time + 2) % 24;
      posY += gabY;
    }

    // 애니메이션시 하단 부분 레이블과 라인이 비지 않도록 그려준다.
    while (posY <= -topPosition + chartHeight) {
      time = (time + 2) % 24;
      posY += gabY;
      _drawLabelAndLine(canvas, size, posY, time);
    }
  }

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}

  @override
  List generateCoordinates(Size size) => [];

  @override
  bool shouldRepaint(covariant TimeYLabelPainter oldDelegate) {
    return oldDelegate.topHour != this.topHour ||
        oldDelegate.bottomHour != this.bottomHour;
  }
}
