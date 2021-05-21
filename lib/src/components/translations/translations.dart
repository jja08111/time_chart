import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class Translations {
  Translations(this._context);

  final BuildContext _context;

  String get languageCode =>
      Localizations.localeOf(_context).toString().substring(0, 2);

  bool get isKorean => languageCode == 'ko';

  String get shortHour {
    if (isKorean) return "시간";
    return "hr";
  }

  String get shortMinute {
    if (isKorean) return "분";
    return "min";
  }

  /// 시간 형식이 오전 10:00 처럼 되어있으면 'true', 10:00 AM 이면 'false'를 반환한다
  bool get isAHMM {
    return MaterialLocalizations.of(_context).timeOfDayFormat() ==
        TimeOfDayFormat.a_space_h_colon_mm;
  }

  String dateFormat(String pattern, DateTime date) {
    initializeDateFormatting('en', null);
    return DateFormat(pattern, languageCode).format(date);
  }

  /// en: Jan 31 - Feb 1
  ///
  /// ko: 1월 31일 - 2월 1일
  String compactDateTimeRange(DateTimeRange range) {
    final shortMonthList = getShortMonthList(_context);
    final daySuffix = isKorean ? '일' : '';
    final sleepTimeMonth = shortMonthList[range.start.month - 1];
    final wakeUpMonth = shortMonthList[range.end.month - 1];

    String result;
    if (range.start.day != range.end.day) {
      if (range.start.month != range.end.month)
        result = '$sleepTimeMonth ${range.start.day}$daySuffix - '
            '$wakeUpMonth ${range.end.day}$daySuffix';
      else
        result = '$wakeUpMonth ${range.start.day} - ${range.end.day}$daySuffix';
    } else {
      result = '$wakeUpMonth ${range.end.day}$daySuffix';
    }

    return result;
  }

  /// en: 11:30 AM
  /// ko: 오전 11:30
  Widget formatTimeOfDayWidget({
    required Widget a,
    required Widget hMM,
    double interval = 4,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) {
    final _isAHMM = isAHMM;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        if (_isAHMM) ...<Widget>[
          a,
          SizedBox(width: interval),
        ],
        hMM,
        if (!_isAHMM) ...<Widget>[
          SizedBox(width: interval),
          a,
        ],
      ],
    );
  }

  /// 번역된 시간을 반환한다.
  ///
  /// 예를 들어 한국어인 경우 [hour]가 13이면 오후 1시를 반환한다.
  /// 영어인 경우는 1 PM 을 반환한다.
  String formatHourOnly(int hour) {
    final date = DateTime(1, 1, 1, hour);
    String format;
    if (isAHMM)
      format = 'a h시';
    else
      format = 'h a';
    return dateFormat(format, date);
  }
}

/// 일,월,화,... Sun, Mon, Tue,...
List<String> getShortWeekdayList(BuildContext context) {
  return dateTimeSymbolMap()[_locale(context)].SHORTWEEKDAYS;
}

/// 1월, 2월, 3월,... Jan, Feb, Mar,...
List<String> getShortMonthList(BuildContext context) {
  return dateTimeSymbolMap()[_locale(context)].SHORTMONTHS;
}

String _locale(BuildContext context) {
  return Localizations.localeOf(context).toString().substring(0, 2);
}
