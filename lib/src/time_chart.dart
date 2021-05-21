import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:touchable/touchable.dart';

import 'components/painter/amount_chart/amount_x_label_painter.dart';
import 'components/painter/amount_chart/amount_y_label_painter.dart';
import 'components/painter/time_chart/time_x_label_painter.dart';
import 'components/painter/border_line_painter.dart';
import 'components/scroll/custom_scroll_physics.dart';
import 'components/scroll/my_single_child_scroll_view.dart';
import 'components/painter/chart_engine.dart';
import 'components/painter/time_chart/time_y_label_painter.dart';
import 'components/utils/time_assistant.dart';
import 'components/utils/time_data_processor.dart';
import 'components/painter/amount_chart/amount_bar_painter.dart';
import 'components/painter/time_chart/time_bar_painter.dart';
import 'components/tooltip/sleep_tooltip_overlay.dart';
import 'components/tooltip/tooltip_size.dart';
import 'components/view_mode.dart';
import 'components/translations/translations.dart';
import 'components/utils/context_utils.dart';

const double _kStatusBarHeight = 30.0;

enum ChartType {
  time,
  amount,
}

class TimeChart extends StatefulWidget {
  TimeChart({
    Key? key,
    this.chartType = ChartType.time,
    this.width,
    this.height = 280.0,
    this.barColor,
    required this.data,
    this.timeChartSizeAnimationDuration = const Duration(milliseconds: 300),
    this.tooltipDuration = const Duration(seconds: 7),
    this.tooltipBackgroundColor,
    this.tooltipStart = "START",
    this.tooltipEnd = "END",
    required this.viewMode,
  }) : super(key: key);

  /// The type of chart.
  ///
  /// Default is [ChartType.time].
  final ChartType chartType;

  /// Total chart width
  ///
  /// Default is `MediaQuery.of(context).size.width - 32.0`.
  final double? width;

  /// Total chart height
  ///
  /// Default is `280.0`. Actual height is [height] + 4.0([_TimeChartState._topPadding]).
  final double height;

  /// The color of the bar in the chart.
  ///
  /// Default is [accentColor].
  final Color? barColor;

  /// The list of [DateTimeRange].
  ///
  /// First index is latest data, End data is oldest data. It must be sorted
  /// because of correctly painting the chart. This value must not be null.
  final List<DateTimeRange> data;

  /// The size animation duration of time chart when is changed pivot hours.
  ///
  /// Default value is `Duration(milliseconds: 300)`.
  final Duration timeChartSizeAnimationDuration;

  /// The Tooltip duration.
  ///
  /// Default is `Duration(seconds: 7)`.
  final Duration tooltipDuration;

  /// The color of tooltip background.
  ///
  /// [Theme.of(context).dialogBackgroundColor] is default color.
  final Color? tooltipBackgroundColor;

  /// The label of [ChartType.time] tooltip.
  ///
  /// Default is "start"
  final String tooltipStart;

  /// The label of [ChartType.time] tooltip.
  ///
  /// Default is "end"
  final String tooltipEnd;

  /// The chart view mode.
  ///
  /// There is two type [ViewMode.weekly] and [ViewMode.monthly]. This value
  /// must not be null.
  final ViewMode viewMode;

  @override
  _TimeChartState createState() => _TimeChartState();
}

class _TimeChartState extends State<TimeChart>
    with TickerProviderStateMixin, TimeDataProcessor {
  static const Duration _tooltipFadeInDuration = Duration(milliseconds: 150);
  static const Duration _tooltipFadeOutDuration = Duration(milliseconds: 75);

  /// 최상단에 그려진 것들이 잘리지 않기 위해 필요한 상단 패딩값이다.
  static const double _topPadding = 4.0;

  LinkedScrollControllerGroup _scrollControllerGroup =
      LinkedScrollControllerGroup();
  late ScrollController _barController;
  late ScrollController _xLabelController;

  Timer? _updatePivotHourTimer;

  late AnimationController _sizeController;
  late Animation<double> _sizeAnimation;

  /// 툴팁을 띄우기 위해 사용한다.
  OverlayEntry? _overlayEntry;

  /// 툴팁이 떠있는 시간을 정한다.
  Timer? _tooltipHideTimer;

  Rect? _currentVisibleTooltipRect;

  /// 툴팁의 fadeIn out 애니메이션을 다룬다.
  late AnimationController _tooltipController;

  /// 바와 그 양 옆의 여백의 너비를 더한 값이다.
  double? _blockWidth;

  /// 에니메이션 시작시 전체 그래프의 높이
  late double _beginHeight;

  /// 에니메이션 시작시 올바른 위치에서 시작하기 위한 높이 값
  double? _heightForAlignTop;

  double _prevScrollPosition = 0;

  @override
  void initState() {
    super.initState();

    _barController = _scrollControllerGroup.addAndGet();
    _xLabelController = _scrollControllerGroup.addAndGet();

    _sizeController = AnimationController(
      duration: widget.timeChartSizeAnimationDuration,
      vsync: this,
    );
    _tooltipController = AnimationController(
      duration: _tooltipFadeInDuration,
      reverseDuration: _tooltipFadeOutDuration,
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _sizeController,
      curve: Curves.easeInOut,
    );

    _beginHeight = widget.height;
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance!.pointerRouter.addGlobalRoute(_handlePointerEvent);

    WidgetsBinding.instance!.addPostFrameCallback((_) => _addScrollListener());

    processData(widget.data, widget.viewMode, widget.chartType,
        dateWithoutTime(widget.data.first.end.add(const Duration(days: 1))));
  }

  @override
  void dispose() {
    _removeEntry();
    _barController.dispose();
    _xLabelController.dispose();
    _sizeController.dispose();
    _tooltipController.dispose();
    _cancelTimer();
    GestureBinding.instance!.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    super.dispose();
  }

  void _addScrollListener() {
    final viewModeLimitDay = getViewModeLimitDay(widget.viewMode);
    final minDifference = _blockWidth! * viewModeLimitDay;

    _scrollControllerGroup.addOffsetChangedListener(() {
      final difference =
          (_scrollControllerGroup.offset - _prevScrollPosition).abs();

      if (difference >= minDifference) {
        setState(() {
          _prevScrollPosition = _scrollControllerGroup.offset;
        });
      }
    });
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_overlayEntry == null) return;
    if (event is PointerDownEvent) _removeEntry();
  }

  /// 해당 바(bar)를 눌렀을 경우 툴팁을 띄운다.
  ///
  /// 위치는 x축 방향 left, y축 방향 top 만큼 떨어진 위치이다.
  ///
  /// 오버레이 엔트리를 이곳에서 관리하기 위해 콜백하여 이용한다.
  void _tooltipCallback({
    DateTimeRange? range,
    double? amount,
    DateTime? amountDate,
    required Rect rect,
    required ScrollPosition position,
    required double barWidth,
  }) {
    assert(range != null || amount != null);
    // 현재 보이는 그래프의 범위를 벗어난 바의 툴팁은 무시한다.
    final viewRange = _blockWidth! * getViewModeLimitDay(widget.viewMode);
    final actualPosition = position.maxScrollExtent - position.pixels;
    if (rect.left < actualPosition || actualPosition + viewRange < rect.left)
      return;

    // 현재 보이는 툴팁이 다시 호출되면 무시한다.
    if ((_tooltipHideTimer?.isActive ?? false) &&
        _currentVisibleTooltipRect == rect) return;
    _currentVisibleTooltipRect = rect;

    HapticFeedback.vibrate();
    _removeEntry();

    _tooltipController.forward();
    _overlayEntry = OverlayEntry(
      builder: (_) => _buildOverlay(
        rect,
        position,
        barWidth,
        range: range,
        amount: amount,
        amountDate: amountDate,
      ),
    );
    Overlay.of(context)!.insert(_overlayEntry!);
    _tooltipHideTimer = Timer(widget.tooltipDuration, _removeEntry);
  }

  double get _tooltipPadding => kTooltipArrowWidth + 2.0;

  Widget _buildOverlay(
    Rect rect,
    ScrollPosition position,
    double barWidth, {
    DateTimeRange? range,
    double? amount,
    DateTime? amountDate,
  }) {
    final chartType = amount == null ? ChartType.time : ChartType.amount;
    // 현재 위젯의 위치를 얻는다.
    final pivotOffset = ContextUtils.getOffsetFromContext(context)!;
    // amount 가 null 이면 ChartType.time 이고, 아니면 ChartType.amount 이다.
    final Size tooltipSize =
        chartType == ChartType.time ? kTimeTooltipSize : kAmountTooltipSize;

    final minTop =
        kToolbarHeight + _kStatusBarHeight - (tooltipSize.height) / 2;

    final candidateTop = rect.top +
        pivotOffset.dy -
        tooltipSize.height / 2 +
        _topPadding +
        (chartType == ChartType.time
            ? (rect.bottom - rect.top) / 2
            : kTooltipArrowHeight / 2);

    final scrollPixels = position.maxScrollExtent - position.pixels;
    final localLeft = rect.left + pivotOffset.dx - scrollPixels;
    final top = max(candidateTop, minTop);

    Direction direction = Direction.left;
    double left = localLeft - tooltipSize.width - _tooltipPadding;
    // 툴팁을 바의 오른쪽에 배치해야 하는 경우
    if (left < pivotOffset.dx) {
      direction = Direction.right;
      left = localLeft + barWidth + _tooltipPadding;
    }

    return Positioned(
      // 바 옆에 [tooltip]을 띄운다.
      top: top,
      left: left,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _tooltipController,
          curve: Curves.fastOutSlowIn,
        ),
        child: SleepTooltipOverlay(
          backgroundColor: widget.tooltipBackgroundColor,
          chartType: chartType,
          bottomHour: bottomHour,
          timeRange: range,
          amountHour: amount,
          amountDate: amountDate,
          direction: direction,
          start: widget.tooltipStart,
          end: widget.tooltipEnd,
        ),
      ),
    );
  }

  /// 현재 존재하는 툴팁을 제거한다.
  void _removeEntry() {
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _cancelTimer() {
    _updatePivotHourTimer?.cancel();
  }

  double _getRightMargin(BuildContext context) {
    final translations = Translations(context);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: translations.formatHourOnly(12),
        style: Theme.of(context)
            .textTheme
            .bodyText2!
            .copyWith(color: Colors.white38),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp.width + kYLabelMargin;
  }

  void _handlePanDown(_) {
    CustomScrollPhysics.setPanDownPixels(
        widget.chartType, _barController.position.pixels);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.chartType == ChartType.amount) return false;

    if (notification is ScrollStartNotification) {
      _cancelTimer();
    } else if (notification is ScrollEndNotification) {
      _updatePivotHourTimer =
          Timer(const Duration(milliseconds: 800), _timerCallback);
    }
    return true;
  }

  void _timerCallback() {
    final beforeFirstDataHasChanged = firstDataHasChanged;
    final beforeTopHour = topHour;
    final beforeBottomHour = bottomHour;

    final block =
        getCurrentBlockIndex(_barController.position, _blockWidth!).toInt();
    final pivotEnd = dateWithoutTime(widget.data.first.end).add(
        Duration(days: -block + (block > 0 && firstDataHasChanged ? 2 : 1)));

    processData(widget.data, widget.viewMode, widget.chartType, pivotEnd);

    if (topHour == beforeTopHour && bottomHour == beforeBottomHour) return;

    if (beforeFirstDataHasChanged != firstDataHasChanged) {
      // 하루가 추가 혹은 삭제되는 경우 x축 방향으로 발생하는 차이를 해결할 값이다.
      final add = firstDataHasChanged ? _blockWidth! : -_blockWidth!;

      _barController.jumpTo(_barController.position.pixels + add);
      CustomScrollPhysics.addPanDownPixels(widget.chartType, add);
    }

    _heightAnimation(beforeTopHour!, beforeBottomHour!);
  }

  double get heightWithoutLabel => widget.height - kXLabelHeight;

  void _heightAnimation(int beforeTopHour, int beforeBottomHour) {
    final beforeDiff =
        hourDiffBetween(beforeTopHour, beforeBottomHour).toDouble();
    final currentDiff = hourDiffBetween(topHour, bottomHour).toDouble();

    final candidateUpward = diffBetween(beforeTopHour, topHour!);
    final candidateDownWard = -diffBetween(topHour!, beforeTopHour);

    // (candidate)중에서 current top-bottom hour 범위에 들어오는 것을 선택한다.
    final topDiff =
        isDirUpward(beforeTopHour, beforeBottomHour, topHour!, bottomHour!)
            ? candidateUpward
            : candidateDownWard;

    setState(() {
      _beginHeight =
          (currentDiff / beforeDiff) * heightWithoutLabel + kXLabelHeight;
      _heightForAlignTop = (_beginHeight - widget.height) / 2 +
          (topDiff / beforeDiff) * heightWithoutLabel;
    });
    _sizeController.reverse(from: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final int viewModeLimitDay = getViewModeLimitDay(widget.viewMode);
    final double outerHeight = _topPadding + widget.height;
    final double width =
        widget.width ?? MediaQuery.of(context).size.width - 32.0;
    final double yLabelWidth = _getRightMargin(context);

    _blockWidth ??= (width - yLabelWidth) / viewModeLimitDay;
    final key = ValueKey((topHour ?? 0) + (bottomHour ?? 1) * 100);
    final innerSize = Size(
      _blockWidth! * max(dayCount!, viewModeLimitDay),
      double.infinity,
    );

    return GestureDetector(
      onPanDown: _handlePanDown,
      child: SizedBox(
        height: outerHeight,
        width: width,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            // # #
            // # #
            SizedBox(
              width: width,
              height: outerHeight,
            ),
            _buildAnimatedBox(
              topPadding: _topPadding,
              width: width,
              builder: (context, topPosition) => CustomPaint(
                key: key,
                size: Size(width, double.infinity),
                painter: _buildYLabelPainter(context, topPosition),
              ),
            ),
            //-----
            // # .
            // # .
            Positioned(
              top: _topPadding,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: width - yLabelWidth,
                    height: widget.height,
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: BorderLinePainter()),
                  ),
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: _horizontalScrollView(
                        key: key,
                        controller: _xLabelController,
                        child: CustomPaint(
                          size: innerSize,
                          painter: _buildXLabelPainter(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //-----
            // # .
            // . .
            Positioned(
              top: _topPadding,
              child: Stack(
                children: [
                  SizedBox(
                    width: width - yLabelWidth,
                    height: widget.height - kXLabelHeight,
                  ),
                  _buildAnimatedBox(
                    bottomPadding: kXLabelHeight,
                    width: width - yLabelWidth,
                    child: _horizontalScrollView(
                      key: key,
                      controller: _barController,
                      child: CanvasTouchDetector(
                        builder: (context) => CustomPaint(
                          size: innerSize,
                          painter: _buildBarPainter(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalScrollView({
    required Widget child,
    required Key key,
    required ScrollController? controller,
  }) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification overScroll) {
        overScroll.disallowGlow();
        return false;
      },
      child: MySingleChildScrollView(
        reverse: true,
        scrollDirection: Axis.horizontal,
        controller: controller,
        physics: CustomScrollPhysics(
          itemDimension: _blockWidth!,
          viewMode: widget.viewMode,
          chartType: widget.chartType,
        ),
        child: RepaintBoundary(
          key: key,
          child: child,
        ),
      ),
    );
  }

  Widget _buildAnimatedBox({
    Widget? child,
    required double width,
    double topPadding = 0.0,
    double bottomPadding = 0.0,
    Function(BuildContext, double)? builder,
  }) {
    assert(
        (child != null && builder == null) || child == null && builder != null);

    final _heightAnimation = Tween<double>(
      begin: widget.height,
      end: _beginHeight,
    ).animate(_sizeAnimation);
    final _heightForAlignTopAnimation = Tween<double>(
      begin: 0,
      end: _heightForAlignTop,
    ).animate(_sizeAnimation);

    return AnimatedBuilder(
      animation: _sizeAnimation,
      builder: (context, child) {
        final topPosition = (widget.height - _heightAnimation.value) / 2 +
            _heightForAlignTopAnimation.value +
            topPadding;
        return Positioned(
          right: 0,
          top: topPosition,
          child: Container(
            height: _heightAnimation.value - bottomPadding,
            width: width,
            alignment: Alignment.center,
            child: child != null
                ? child
                : builder!(context, topPosition - _topPadding),
          ),
        );
      },
      child: child,
    );
  }

  CustomPainter _buildYLabelPainter(BuildContext context, double topPosition) {
    switch (widget.chartType) {
      case ChartType.time:
        return TimeYLabelPainter(
          context: context,
          viewMode: widget.viewMode,
          topHour: topHour,
          bottomHour: bottomHour,
          chartHeight: widget.height,
          topPosition: topPosition,
        );
      case ChartType.amount:
        return AmountYLabelPainter(
          context: context,
          viewMode: widget.viewMode,
          topHour: topHour,
          bottomHour: bottomHour,
        );
    }
  }

  CustomPainter _buildXLabelPainter(BuildContext context) {
    switch (widget.chartType) {
      case ChartType.time:
        return TimeXLabelPainter(
          scrollController: _xLabelController,
          scrollOffset:
              _xLabelController.hasClients ? _xLabelController.offset : 0,
          context: context,
          viewMode: widget.viewMode,
          firstValueDateTime: processedSleepData.first.end,
          dayCount: dayCount,
          firstDataHasChanged: firstDataHasChanged,
        );
      case ChartType.amount:
        return AmountXLabelPainter(
          scrollController: _xLabelController,
          scrollOffset:
              _xLabelController.hasClients ? _xLabelController.offset : 0,
          context: context,
          viewMode: widget.viewMode,
          firstValueDateTime: processedSleepData.first.end,
          dayCount: dayCount,
        );
    }
  }

  CustomPainter _buildBarPainter(BuildContext context) {
    switch (widget.chartType) {
      case ChartType.time:
        return TimeBarPainter(
          scrollController: _barController,
          scrollOffset: _barController.hasClients ? _barController.offset : 0,
          context: context,
          tooltipCallback: _tooltipCallback,
          sleepData: processedSleepData,
          barColor: widget.barColor,
          topHour: topHour!,
          bottomHour: bottomHour!,
          dayCount: dayCount,
          viewMode: widget.viewMode,
          isFirstDataChanged: firstDataHasChanged,
        );
      case ChartType.amount:
        return AmountBarPainter(
          scrollController: _barController,
          scrollOffset: _barController.hasClients ? _barController.offset : 0,
          context: context,
          sleepData: processedSleepData,
          barColor: widget.barColor,
          topHour: topHour,
          bottomHour: bottomHour,
          tooltipCallback: _tooltipCallback,
          dayCount: dayCount,
          viewMode: widget.viewMode,
        );
    }
  }
}
