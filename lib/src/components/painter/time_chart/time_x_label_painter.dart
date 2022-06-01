import 'package:time_chart/src/components/painter/x_label_painter.dart';

class TimeXLabelPainter extends XLabelPainter {
  TimeXLabelPainter({
    required super.viewMode,
    required super.context,
    required super.dayCount,
    required super.firstValueDateTime,
    required super.repaint,
    required super.scrollController,
    required super.isFirstDataMovedNextDay,
  });
}
