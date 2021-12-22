import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/custom_paint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/components/painter/chart_engine.dart';
import 'package:time_chart/time_chart.dart';

void main() {
  testWidgets('indexOf function test', (tester) async {
    ChartEngineMock? chartEngineMock;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          chartEngineMock = ChartEngineMock(context, ViewMode.weekly);
          return Placeholder();
        },
      ),
    );
    final List<DateTimeRange> dateTimeList = [];
    final startDateTime = DateTime(2021, 1, 1, 0, 0);
    final random = Random();
    final count = 1000;
    // The list must be in descending order.
    for (int i = count; i >= 0; --i) {
      final hour = random.nextInt(3);
      final minute = random.nextInt(60);
      dateTimeList.add(
        DateTimeRange(
          start: startDateTime.add(
            Duration(days: i, hours: hour, minutes: minute),
          ),
          end: startDateTime.add(
            Duration(days: i, hours: hour + 8, minutes: minute),
          ),
        ),
      );
    }

    expect(
      chartEngineMock!.indexOf(startDateTime, dateTimeList),
      count - ChartEngine.toleranceDay,
    );
    expect(
      chartEngineMock!.indexOf(
        startDateTime.add(Duration(days: 3)),
        dateTimeList,
      ),
      count - 3 - ChartEngine.toleranceDay,
    );
    expect(
      chartEngineMock!.indexOf(
        startDateTime.add(Duration(days: 500)),
        dateTimeList,
      ),
      count - 500 - ChartEngine.toleranceDay,
    );
    expect(
      chartEngineMock!.indexOf(
        startDateTime.add(Duration(days: 777)),
        dateTimeList,
      ),
      count - 777 - ChartEngine.toleranceDay,
    );
    expect(
      chartEngineMock!.indexOf(
        startDateTime.add(Duration(days: count)),
        dateTimeList,
      ),
      0, // did not subtract toleranceDay because index cannot be negative.
    );
  });
}

class ChartEngineMock extends ChartEngine {
  ChartEngineMock(BuildContext context, ViewMode viewMode)
      : super(
          context: context,
          viewMode: viewMode,
        );

  @override
  void drawBar(Canvas canvas, Size size, List coordinates) {}

  @override
  void drawYLabels(Canvas canvas, Size size) {}

  @override
  List generateCoordinates(Size size) {
    return [];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
