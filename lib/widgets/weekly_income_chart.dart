import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:postnow/models/daily_income.dart';
import 'package:postnow/models/weekly_income.dart';

class WeeklyIncomeChart extends StatelessWidget {
  final WeeklyIncome _weeklyIncome;

  WeeklyIncomeChart(this._weeklyIncome);

  @override
  Widget build(BuildContext context) {
    List<charts.Series<DailyIncome, String>> series = [
      charts.Series(
        id: "WeeklyIncome",
        data: _weeklyIncome.dailyIncomes,
        domainFn: (DailyIncome income, _) => income.getDayName(),
        measureFn: (DailyIncome income, _) => income.income,
        seriesColor: charts.ColorUtil.fromDartColor(Colors.green),
      )
    ];

    final customTickFormatter =  charts.BasicNumericTickFormatterSpec((num value) => '$value €');

    return charts.BarChart(
      series,
      animate: true,
      primaryMeasureAxis: new charts.NumericAxisSpec(tickFormatterSpec: customTickFormatter),
    );
  }
}