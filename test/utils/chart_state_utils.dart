import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/chart.dart';

ChartState getChartState(WidgetTester tester) {
  return tester.state(find.byType(Chart));
}
