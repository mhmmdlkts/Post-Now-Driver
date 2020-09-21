import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:postnow/models/daily_income.dart';
import 'package:postnow/models/weekly_income.dart';

class WeeklyIncomeChart extends StatelessWidget {
  final WeeklyIncome _weeklyIncome;
  final ValueChanged<double> func;

  WeeklyIncomeChart(this._weeklyIncome, this.func);

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

    return Stack(
      alignment: Alignment.center,
      children: [
        !_weeklyIncome.isInitialized? CircularProgressIndicator():Container(),
        charts.BarChart(
          series,
          animate: _weeklyIncome.isInitialized,
          primaryMeasureAxis: new charts.NumericAxisSpec(tickFormatterSpec: customTickFormatter),
          selectionModels: [
            SelectionModelConfig<String>(
                updatedListener: (SelectionModel model) {
                  if(model.hasDatumSelection) {
                    func.call(model.selectedSeries[0].measureFn(
                        model.selectedDatum[0].index));
                  }
                }
            )
          ],
        )
      ],
    );
  }
}