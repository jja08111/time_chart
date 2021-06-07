import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/time_chart.dart';
import 'data_pool.dart';

void main() {
  group('Chart pivot hours tests.', () {
    testWidgets('TimeChart pivot hours test.', (tester) async {
      await tester.pumpWidget(TimeChart(
        data: smallDataList,
        viewMode: ViewMode.monthly,
      ));
      final ChartState chartState = tester.state(find.byType(Chart));

      expect(chartState.topHour, 22);
      expect(chartState.bottomHour, 10);
    });
  });
}
// command: flutter pub run test test\time_chart_test.dart
// flutter test test\time_chart_test.dart
