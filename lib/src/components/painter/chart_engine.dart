import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../view_mode.dart';
import '../translations/translations.dart';

const double kYLabelMargin = 12.0;
const int _kPivotYLabelHour = 12;

const double kXLabelHeight = 32.0;

const double kLineStrokeWidth = 0.8;

const double kBarWidthRatio = 0.7;
const double kBarPaddingWidthRatio = (1 - kBarWidthRatio) / 2;

 Color kLineColor1 = Color(0x44757575);
 Color kLineColor2 = Color(0x77757575);
 Color kLineColor3 = Color(0xAA757575);
 Color kTextColor = Color(0xFF757575);

abstract class ChartEngine extends CustomPainter {
  static const int toleranceDay = 1;

  ChartEngine({
    this.scrollController,
    int? dayCount,
    required this.viewMode,
    this.firstValueDateTime,
    required this.context,
    super.repaint,
  })  : dayCount = math.max(dayCount ?? -1, viewMode.dayCount),
        translations = Translations(context);

  final ScrollController? scrollController;
  final int dayCount;
  final ViewMode viewMode;
  final DateTime? firstValueDateTime;
  final BuildContext context;
  final Translations translations;

  int get currentDayFromScrollOffset {
    if (!scrollController!.hasClients) return 0;
    return (scrollController!.offset / blockWidth!).floor();
  }

  /// 전체 그래프의 오른쪽 레이블이 들어갈 간격의 크기이다.
  double get rightMargin => _rightMargin;

  /// 바 너비의 크기이다.
  double get barWidth => _barWidth;

  /// 바를 적절하게 정렬하기 위한 값이다.
  double get paddingForAlignedBar => _paddingForAlignedBar;

  /// (바와 바 사이의 여백의 너비 + 바의 너비) => 블럭 너비의 크기이다.
  double? get blockWidth => _blockWidth;

  TextTheme get textTheme => Theme.of(context).textTheme;

  double _rightMargin = 0.0;
  double _barWidth = 0.0;
  double _paddingForAlignedBar = 0.0;
  double? _blockWidth;

  void setRightMargin() {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: translations.formatHourOnly(_kPivotYLabelHour),
        style: textTheme.bodyMedium!.copyWith(color: kTextColor),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    _rightMargin = tp.width + kYLabelMargin;
  }

  void setDefaultValue(Size size) {
    setRightMargin();
    _blockWidth = size.width / dayCount;
    _barWidth = blockWidth! * kBarWidthRatio;
    // 바의 위치를 가운데로 정렬하기 위한 [padding]
    _paddingForAlignedBar = blockWidth! * kBarPaddingWidthRatio;
  }
}
