import 'package:flutter/material.dart';
import 'chart.dart';
import 'components/chart_style.dart';
import 'components/chart_type.dart';
import 'components/view_mode.dart';

/// The padding to prevent cut off the top of the chart.
const double kTimeChartTopPadding = 4.0;

class TimeChart extends StatelessWidget {
  const TimeChart({
    Key? key,
    this.chartType = ChartType.time,
    this.width,
    this.height = 280.0,
    required this.data,
    this.timeChartSizeAnimationDuration = const Duration(milliseconds: 300),
    this.tooltipDuration = const Duration(seconds: 7),
    this.tooltipStart = "START",
    this.tooltipEnd = "END",
    this.activeTooltip = true,
    this.viewMode = ViewMode.weekly,
    this.defaultPivotHour = 0,
    this.chartStyle,
  })  : assert(0 <= defaultPivotHour && defaultPivotHour < 24),
        super(key: key);

  /// The type of chart.
  ///
  /// Default is the [ChartType.time].
  final ChartType chartType;

  /// Total chart width.
  ///
  /// Default is parent box width.
  final double? width;

  /// Total chart height
  ///
  /// Default is `280.0`. Actual height is [height] + 4.0([kTimeChartTopPadding]).
  final double height;

  /// The list of [DateTimeRange].
  ///
  /// The first index is the latest data, The end data is the oldest data.
  /// It must be sorted because of correctly painting the chart.
  ///
  /// ```dart
  /// assert(data[0].isAfter(data[1])); // true
  /// ```
  final List<DateTimeRange> data;

  /// The size animation duration of time chart when is changed pivot hours.
  ///
  /// Default value is `Duration(milliseconds: 300)`.
  final Duration timeChartSizeAnimationDuration;

  /// The Tooltip duration.
  ///
  /// Default is `Duration(seconds: 7)`.
  final Duration tooltipDuration;

  /// The label of [ChartType.time] tooltip.
  ///
  /// Default is "start"
  final String tooltipStart;

  /// The label of [ChartType.time] tooltip.
  ///
  /// Default is "end"
  final String tooltipEnd;

  /// If it's `true` active showing the tooltip when tapped a bar.
  ///
  /// Default value is `true`
  final bool activeTooltip;

  /// The chart view mode.
  ///
  /// There is two type [ViewMode.weekly] and [ViewMode.monthly].
  final ViewMode viewMode;

  /// The hour is used as a pivot if the data time range is fully visible or
  /// there is no data when the type is the [ChartType.time].
  ///
  /// For example, this value will be used when you use the data like below.
  /// ```dart
  /// [DateTimeRange(
  ///       start: DateTime(2021, 12, 17, 3, 12),
  ///       end: DateTime(2021, 12, 18, 2, 30),
  /// )];
  /// ```
  ///
  /// If there is no data when the type is the [ChartType.amount], 8 Hours is
  /// used as a top hour, not this value.
  ///
  /// It must be in the range of 0 to 23.
  final int defaultPivotHour;

  /// The style of the chart.
  ///
  /// tooltipBackgroundColor
  /// [Theme.of(context).dialogBackgroundColor] is default color.
  ///
  /// barColor
  /// Default is the `Theme.of(context).colorScheme.secondary`.
  ///
  /// labelColor
  /// Default is the `Theme.of(context).colorScheme.onSurface`.
  ///
  /// verticalGridColor
  /// Default is the `Theme.of(context).colorScheme.onSurface`.
  ///
  /// horizontalGridColor
  /// Default is the `Theme.of(context).colorScheme.onSurface`.
  ///

  final ChartStyle? chartStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final actualWidth = width ?? box.maxWidth;

      return SizedBox(
        height: height + kTimeChartTopPadding,
        width: actualWidth,
        child: Chart(
            key: ValueKey(viewMode),
            chartType: chartType,
            width: actualWidth,
            height: height,
            data: data,
            timeChartSizeAnimationDuration: timeChartSizeAnimationDuration,
            tooltipDuration: tooltipDuration,
            tooltipStart: tooltipStart,
            tooltipEnd: tooltipEnd,
            activeTooltip: activeTooltip,
            viewMode: viewMode,
            defaultPivotHour: defaultPivotHour,
            chartStyle: chartStyle),
      );
    });
  }
}
