import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/time_chart.dart';

ChartState getChartState(WidgetTester tester) {
  return tester.state(find.byType(Chart));
}

void main() {
  group('Time chart tests', () {
    testWidgets('Time chart data merging test', (tester) async {
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

    testWidgets('Time chart empty space comparing test', (tester) async {
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
  });
}
