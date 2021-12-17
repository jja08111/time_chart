import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/components/utils/time_data_processor.dart';
import 'package:time_chart/time_chart.dart';

import '../utils/chart_state_utils.dart';

void main() {
  group('Time chart pivot hours test', () {
    testWidgets('merge if has overlapping time in time chart', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 2, 24, 23, 15),
              end: DateTime(2021, 2, 25, 7, 30),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 22, 1, 55),
              end: DateTime(2021, 2, 22, 9, 12),
            ),
          ],
          viewMode: ViewMode.monthly,
        ),
      ));
      final ChartState chartState = getChartState(tester);

      expect(chartState.topHour, 22);
      expect(chartState.bottomHour, 10);
    });

    testWidgets('compare empty space for setting pivot hours', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 2, 1, 22, 12),
              end: DateTime(2021, 2, 2, 3, 30),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 4, 52),
              end: DateTime(2021, 2, 2, 9, 0),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 11, 39),
              end: DateTime(2021, 2, 2, 18, 2),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 18, 42),
              end: DateTime(2021, 2, 2, 21, 22),
            ),
          ],
          viewMode: ViewMode.monthly,
        ),
      ));
      final ChartState chartState = getChartState(tester);

      expect(chartState.topHour, 11);
      expect(chartState.bottomHour, 9);
    });

    testWidgets('compare and merge time for setting pivot hours',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 2, 1, 22, 12),
              end: DateTime(2021, 2, 2, 3, 30),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 2, 52),
              end: DateTime(2021, 2, 2, 9, 0),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 11, 39),
              end: DateTime(2021, 2, 2, 16, 2),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 14, 42),
              end: DateTime(2021, 2, 2, 21, 22),
            ),
          ],
          viewMode: ViewMode.weekly,
        ),
      ));
      final ChartState chartState = getChartState(tester);

      expect(chartState.topHour, 11);
      expect(chartState.bottomHour, 9);
    });

    testWidgets('default pivot hours is used if there are no space',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 2, 1, 22, 12),
              end: DateTime(2021, 2, 2, 3, 30),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 2, 52),
              end: DateTime(2021, 2, 2, 9, 0),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 8, 39),
              end: DateTime(2021, 2, 2, 18, 2),
            ),
            DateTimeRange(
              start: DateTime(2021, 2, 2, 17, 42),
              end: DateTime(2021, 2, 2, 22, 22),
            ),
          ],
          viewMode: ViewMode.monthly,
        ),
      ));
      final ChartState chartState = getChartState(tester);

      expect(chartState.topHour, TimeDataProcessor.defaultPivotHour);
      expect(chartState.bottomHour, TimeDataProcessor.defaultPivotHour);
    });

    testWidgets('set both pivot hours to 12 AM if both pivot hours are the same',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TimeChart(
          data: [
            DateTimeRange(
              start: DateTime(2021, 12, 17, 3, 12),
              end: DateTime(2021, 12, 18, 2, 30),
            ),
          ],
          viewMode: ViewMode.monthly,
        ),
      ));
      final ChartState chartState = getChartState(tester);

      expect(chartState.topHour, TimeDataProcessor.defaultPivotHour);
      expect(chartState.bottomHour, TimeDataProcessor.defaultPivotHour);
    });
  });
}
