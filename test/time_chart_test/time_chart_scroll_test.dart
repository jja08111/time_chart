import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/chart.dart';
import 'package:time_chart/src/components/scroll/my_single_child_scroll_view.dart';
import 'package:time_chart/time_chart.dart';

import '../utils/chart_state_utils.dart';

void main() {
  group('Time chart scrolling test', () {
    testWidgets('scroll weekly time chart', (tester) async {
      tester.view.physicalSize = const Size(400, 800);

      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 10, 22, 23, 55),
              end: DateTime(2021, 10, 23, 8, 0),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 21, 21, 15),
              end: DateTime(2021, 10, 22, 6, 10),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 20, 12, 20),
              end: DateTime(2021, 10, 20, 14, 0),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 20, 0, 17),
              end: DateTime(2021, 10, 20, 7, 46),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 19, 0, 45),
              end: DateTime(2021, 10, 19, 9, 5),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 14, 2, 34),
              end: DateTime(2021, 10, 14, 9, 44),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 13, 16, 4),
              end: DateTime(2021, 10, 13, 16, 36),
            ),
            DateTimeRange(
              start: DateTime(2021, 10, 13, 3, 18),
              end: DateTime(2021, 10, 13, 8, 33),
            ),
          ],
          viewMode: ViewMode.weekly,
        ),
      ));
      await tester.pump();

      final ChartState chartState = getChartState(tester);
      final scrollViewFinder = find.byType(MySingleChildScrollView);

      expect(chartState.topHour, 20);
      expect(chartState.bottomHour, 14);

      await tester.drag(scrollViewFinder.last, const Offset(500, 0));
      // waiting for changing pivot hours
      await tester.pump(const Duration(seconds: 3));

      expect(chartState.topHour, 23);
      expect(chartState.bottomHour, 17);
    });
  });
}
