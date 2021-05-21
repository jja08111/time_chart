# time_chart


[![pub package](https://img.shields.io/pub/v/time_chart.svg)](https://pub.dev/packages/time_chart)

An amazing time chart in Flutter.

### Chart Types

|                          TimeChart                           |                         AmountChart                          |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| ![](https://github.com/jja08111/time_chart/blob/main/assets/images/time_chart/weekly_time_chart.gif?raw=true) | ![](https://github.com/jja08111/time_chart/blob/main/assets/images/amount_chart/weekly_amount_chart.gif?raw=true) |
| ![](https://github.com/jja08111/time_chart/blob/main/assets/images/time_chart/monthly_time_chart.gif?raw=true) | ![](https://github.com/jja08111/time_chart/blob/main/assets/images/amount_chart/monthly_amount_chart.gif?raw=true) |



## Getting Started

### 1 - Depend on it

Add it to your package's pubspec.yaml file

```yml
dependencies:
  time_chart: ^0.2.2
```

### 2 - Install it

Install packages from the command line

```sh
flutter packages get
```

### 3 - Usage

Just input your `DateTimeRange` list to `data:` argument. *The list must be sorted.* First data is
latest, last data is oldest. And set the `ViewMode`.



## Example

```dart
import 'package:flutter/material.dart';
import 'package:time_chart/time_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  // Data must be sorted.
  final data = [
    DateTimeRange(
      start: DateTime(2021,2,24,23,15),
      end: DateTime(2021,2,25,7,30),
    ),
    DateTimeRange(
      start: DateTime(2021,2,22,1,55),
      end: DateTime(2021,2,22,9,12),
    ),
    DateTimeRange(
      start: DateTime(2021,2,20,0,25),
      end: DateTime(2021,2,20,7,34),
    ),
    DateTimeRange(
      start: DateTime(2021,2,17,21,23),
      end: DateTime(2021,2,18,4,52),
    ),
    DateTimeRange(
      start: DateTime(2021,2,13,6,32),
      end: DateTime(2021,2,13,13,12),
    ),
    DateTimeRange(
      start: DateTime(2021,2,1,9,32),
      end: DateTime(2021,2,1,15,22),
    ),
    DateTimeRange(
      start: DateTime(2021,1,22,12,10),
      end: DateTime(2021,1,22,16,20),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sizedBox = const SizedBox(height: 16);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Time chart example app')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Weekly time chart'),
                TimeChart(
                  data: data,
                  viewMode: ViewMode.weekly,
                ),
                sizedBox,
                const Text('Monthly time chart'),
                TimeChart(
                  data: data,
                  viewMode: ViewMode.monthly,
                ),
                sizedBox,
                const Text('Weekly amount chart'),
                TimeChart(
                  data: data,
                  chartType: ChartType.amount,
                  viewMode: ViewMode.weekly,
                  barColor: Colors.deepPurple,
                ),
                sizedBox,
                const Text('Monthly amount chart'),
                TimeChart(
                  data: data,
                  chartType: ChartType.amount,
                  viewMode: ViewMode.monthly,
                  barColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Supported languages

|                           English                            |                            Korean                            |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| ![](https://github.com/jja08111/time_chart/blob/main/assets/images/time_chart/weekly_time_chart.gif?raw=true) | ![](https://github.com/jja08111/time_chart/blob/main/assets/images/time_chart/weekly_time_chart_ko.gif?raw=true) |

You can also use korean language by [Internationalizing Flutter apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization).
