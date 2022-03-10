import 'package:flutter/material.dart';
import 'package:touchable/touchable.dart';
import '../../utils/time_assistant.dart' as time_assistant;
import '../chart_engine.dart';
import '../../view_mode.dart';

class TimeBarPainter extends ChartEngine<_TimeBarItem> {
  TimeBarPainter({
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

  @override
  void paint(Canvas canvas, Size size) {
    setDefaultValue(size);
    drawBar(canvas, size, generateCoordinates(size));
  }

  void _drawRRect(
    TouchyCanvas canvas,
    Paint paint,
    DateTimeRange data,
    Rect rect,
    Radius topRadius, [
    Radius bottomRadius = Radius.zero,
  ]) {
    callback(_) => tooltipCallback(
          range: data,
          position: scrollController!.position,
          rect: rect,
          barWidth: barWidth,
        );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: topRadius,
        topRight: topRadius,
        bottomLeft: bottomRadius,
        bottomRight: bottomRadius,
      ),
      paint,
      onTapUp: callback,
      onLongPressStart: callback,
      onLongPressMoveUpdate: callback,
    );
  }

  void _drawOutRangedBar(
    TouchyCanvas canvas,
    Paint paint,
    Size size,
    Rect rect,
    DateTimeRange data,
  ) {
    if (topHour != bottomHour && (bottomHour - topHour).abs() != 24) return;

    final height = size.height;
    bool topOverflow = rect.top < 0.0;

    final top = topOverflow ? height + rect.top : 0.0;
    final bottom = topOverflow ? height : rect.bottom - height;
    final horizontal = topOverflow ? -blockWidth! : blockWidth!;
    final newRect = Rect.fromLTRB(
      rect.left + horizontal,
      top,
      rect.right + horizontal,
      bottom,
    );

    if (topOverflow) {
      _drawRRect(canvas, paint, data, newRect, barRadius);
    } else {
      _drawRRect(canvas, paint, data, newRect, Radius.zero, barRadius);
    }
  }

  @override
  void drawBar(Canvas canvas, Size size, List<_TimeBarItem> coordinates) {
    final touchyCanvas = TouchyCanvas(context, canvas,
        scrollController: scrollController,
        scrollDirection: AxisDirection.left);
    final paint = Paint()
      ..color = barColor ?? Theme.of(context).colorScheme.secondary
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final maxBottom = size.height;

    for (int index = 0; index < coordinates.length; index++) {
      final _TimeBarItem offsetRange = coordinates[index];

      final double left = paddingForAlignedBar + offsetRange.dx;
      final double right = paddingForAlignedBar + offsetRange.dx + barWidth;
      double top = offsetRange.topY;
      double bottom = offsetRange.bottomY;

      Radius topRadius = barRadius;
      Radius bottomRadius = barRadius;

      if (top < 0.0) {
        _drawOutRangedBar(touchyCanvas, paint, size,
            Rect.fromLTRB(left, top, right, bottom), offsetRange.data);
        top = 0.0;
        topRadius = Radius.zero;
      } else if (bottom > maxBottom) {
        _drawOutRangedBar(touchyCanvas, paint, size,
            Rect.fromLTRB(left, top, right, bottom), offsetRange.data);
        bottom = maxBottom;
        bottomRadius = Radius.zero;
      }

      _drawRRect(touchyCanvas, paint, offsetRange.data,
          Rect.fromLTRB(left, top, right, bottom), topRadius, bottomRadius);
    }
  }

  @override
  void drawYLabels(Canvas canvas, Size size) {}

  /// 기준 시간을 이용하여 시간을 변환한다.
  ///
  /// 기준 시간을 기준으로 다른 시간은 아래로 나열된다.
  /// 예를 들어 17시가 기준이라고 할 때 3시가 입력으로 들어오면 27이 반환된다.
  dynamic _convertUsing(var pivot, var value) {
    return value + (value < pivot ? 24 : 0);
  }

  bool _outRangedPivotHour(double sleepTime, double wakeUp) {
    if (sleepTime < 0.0) sleepTime += 24.0;

    // 수면 시간 내에 두 기준 hour 가 속한지 확인한다.
    var top = _convertUsing(sleepTime, topHour);
    var bottom = _convertUsing(sleepTime, bottomHour);
    var candidateWakeUp = _convertUsing(sleepTime, wakeUp);
    if (sleepTime <= top && bottom <= candidateWakeUp) return false;

    // 속하지는 않지만 겹치는 경우를 확인한다.
    top = topHour;
    bottom = bottomHour;
    if (top < bottom) {
      sleepTime = _convertUsing(topHour, sleepTime);
      wakeUp = _convertUsing(topHour, wakeUp);
      top += 24;
    }
    if ((bottom < sleepTime &&
        sleepTime < top &&
        bottom < wakeUp &&
        wakeUp < top)) return true;

    return false;
  }

  @override
  List<_TimeBarItem> generateCoordinates(Size size) {
    List<_TimeBarItem> coordinates = [];

    if (dataList.isEmpty) return [];

    final double intervalOfBars = size.width / dayCount;
    // 제일 아래에 붙은 바가 정각이 아닌 경우 올려 바를 그린다.
    final int pivotBottom = _convertUsing(topHour, bottomHour);
    final int pivotHeight = pivotBottom > topHour ? pivotBottom - topHour : 24;
    final int length = dataList.length;
    final double height = size.height;
    final int viewLimitDay = getViewModeLimitDay(viewMode);

    final dayFromScrollOffset = getDayFromScrollOffset();
    final DateTime startDateTime = getBarRenderStartDateTime(dataList);
    final int startIndex = dataList.getLowerBound(startDateTime);

    for (int index = startIndex; index < length; index++) {
      final wakeUpTimeDouble = dataList[index].end.toDouble();
      final sleepAmountDouble = dataList[index].durationInHours;
      final barPosition =
          1 + dataList.first.end.differenceDateInDay(dataList[index].end);

      if (barPosition - dayFromScrollOffset >
          viewLimitDay + ChartEngine.toleranceDay * 2) break;

      // 좌측 라벨이 아래로 갈수록 시간이 흐르는 것을 표현하기 위해
      // 큰 시간 값과 현재 시간의 차를 구한다.
      double normalizedBottom =
          (pivotBottom - _convertUsing(topHour, wakeUpTimeDouble)) /
              pivotHeight;
      // [normalizedBottom] 에서 [gap]칸 만큼 위로 올린다.
      double normalizedTop = normalizedBottom + sleepAmountDouble / pivotHeight;

      if (normalizedTop < 0.0 && normalizedBottom < 0.0) {
        normalizedTop += 1.0;
        normalizedBottom += 1.0;
      }

      final double bottom = height - normalizedBottom * height;
      final double top = height - normalizedTop * height;
      final double right = size.width - intervalOfBars * barPosition;

      // 그릴 필요가 없는 경우 넘어간다
      if (top == bottom ||
          _outRangedPivotHour(
              wakeUpTimeDouble - sleepAmountDouble, wakeUpTimeDouble)) continue;

      coordinates.add(_TimeBarItem(right, top, bottom, dataList[index]));
    }
    return coordinates;
  }

  @override
  bool shouldRepaint(TimeBarPainter oldDelegate) {
    return oldDelegate.dataList != dataList;
  }
}

class _TimeBarItem {
  final double dx;
  final double topY;
  final double bottomY;
  final DateTimeRange data;

  _TimeBarItem(this.dx, this.topY, this.bottomY, this.data);
}
