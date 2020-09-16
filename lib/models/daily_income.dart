import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/enums/days_enum.dart';

class DailyIncome {
  final Days _day;
  double income;

  DailyIncome(this._day, {this.income = 0.0});

  String getDayName() => ("ENUMS." + _day.toString().toUpperCase()).tr();
}