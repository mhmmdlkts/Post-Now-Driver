import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'overview_service.dart';

class WeekYearToReadableDateInterval {

  static Map _dateJson = Map();

  static Future<void> init() async {
    if (_dateJson.isNotEmpty)
      return;
    await rootBundle.loadString("assets/date/date.json").then((value) {
      _dateJson = json.decode(value);
    });
  }

  static String getReadable({int year, int week, DateTime date}) {
    String nullReturn = "OVERVIEW.TH_WEEK".tr(namedArgs: {'week': week.toString()});
    if (year == null && year == null)
      return nullReturn;

    String key = OverviewService.getChildKey(year, week, checkLastMonth: false);
    String _year = key.split("-").first;
    String _week = key.split("-").last;
    Map obj = _dateJson;
    if (obj == null) return nullReturn;
    obj = obj[_year];
    if (obj == null) return nullReturn;
    obj = obj[_week];
    if (obj == null) return nullReturn;
    if (date == null)
      date = DateTime.now();

    return _getReadableDateFromObj(obj["START"]) + " - " + _getReadableDateFromObj(obj["END"]);
  }

  static String _getReadableDateFromObj(Map json) {
    String readableMonth = ("MONTHS." + json["MONTH"].toString()).tr();
    return json["DAY"].toString() + ". " + readableMonth.substring(0, min(readableMonth.length, 3));
  }
}