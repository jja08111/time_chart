import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/chart.dart';
import 'package:time_chart/time_chart.dart';

import 'data_pool.dart';

void main() {
  testWidgets('Chart updates when the data is replaced', (tester) async {
    List<DateTimeRange> data = data1;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                TimeChart(data: data),
                TextButton(
                  onPressed: () {
                    setState(() {
                      data = data2;
                    });
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await expectLater(
      find.byType(Chart),
      matchesGoldenFile('golden/data1_chart.png'),
      skip: !Platform.isMacOS,
    );

    await tester.tap(find.text('Update'));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(Chart),
      matchesGoldenFile('golden/data2_chart.png'),
      skip: !Platform.isMacOS,
    );
  });

  testWidgets('Chart updates when the data length is changed', (tester) async {
    List<DateTimeRange> data = data1;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                TimeChart(data: data),
                TextButton(
                  onPressed: () {
                    setState(() {
                      data = data3;
                    });
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await expectLater(
      find.byType(Chart),
      matchesGoldenFile('golden/data1_chart.png'),
      skip: !Platform.isMacOS,
    );

    await tester.tap(find.text('Update'));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(Chart),
      matchesGoldenFile('golden/data3_chart.png'),
      skip: !Platform.isMacOS,
    );
  });
}
