import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:postnow/models/daily_income.dart';
import 'package:postnow/models/weekly_income.dart';

class ChartWidget extends StatefulWidget {
  final List<Color> availableColors = [
    Colors.purpleAccent,
    Colors.yellow,
    Colors.greenAccent,
    Colors.orange,
    Colors.pink,
    Colors.redAccent,
  ];

  final WeeklyIncome _weeklyIncome;
  final ValueChanged<DailyIncome> func;
  final int week;

  ChartWidget(this._weeklyIncome, this.week, this.func);


  @override
  _ChartWidgetState createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    if(!widget._weeklyIncome.isInitialized)
      refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.lightBlue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(
                touchedIndex==-1?'OVERVIEW.TH_WEEK'.tr(namedArgs: {'week': widget.week.toString()}):widget._weeklyIncome.dailyIncomes[touchedIndex].getDayName(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                touchedIndex==-1?widget._weeklyIncome.getTotalIncome().toStringAsFixed(2) + " €":widget._weeklyIncome.dailyIncomes[touchedIndex].income.toStringAsFixed(2) + " €",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 38,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: BarChart(
                    widget._weeklyIncome.isInitialized?mainBarData():randomData(),
                    swapAnimationDuration: animDuration,
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    )
    );
  }

  BarChartGroupData makeGroupData(
      int x,
      double y, {
        bool isTouched = false,
        Color barColor = Colors.white,
        double width = 22,
        List<int> showTooltips = const [],
      }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: isTouched ? y * 1.1 : y,
          colors: isTouched ? [randomColor()] : [barColor],
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            y: widget._weeklyIncome.getMaxIncome(),
            colors: [Colors.transparent],
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(7, (i) => makeGroupData(i, widget._weeklyIncome.dailyIncomes[i].income, isTouched: i == touchedIndex));

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String weekDay = widget._weeklyIncome.dailyIncomes[group.x.toInt()].getDayName();
              return BarTooltipItem(weekDay + '\n' + widget._weeklyIncome.dailyIncomes[groupIndex].income.toStringAsFixed(2) + " €", TextStyle(color: Colors.white));
            }),
        touchCallback: (barTouchResponse) {
          setState(() {
            if (barTouchResponse.spot != null &&
                barTouchResponse.touchInput is! FlPanEnd &&
                barTouchResponse.touchInput is! FlLongPressEnd) {
              touchedIndex = barTouchResponse.spot.touchedBarGroupIndex;
              widget.func.call(widget._weeklyIncome.dailyIncomes[touchedIndex]);
            } else {
              touchedIndex = -1;
              widget.func.call(null);
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          getTextStyles: (value) => TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          margin: 16,
          getTitles: (double value) => widget._weeklyIncome.dailyIncomes[value.toInt()].getDayName().substring(0,2),
        ),
        leftTitles: SideTitles(
          showTitles: false,
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
    );
  }

  BarChartData randomData() {
    return BarChartData(
      barTouchData: BarTouchData(
        enabled: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          getTextStyles: (value) =>
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          margin: 16,
          getTitles: (double value) => '',
        ),
        leftTitles: SideTitles(showTitles: false),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(7, (i) {
        return makeGroupData(i, Random().nextInt(15).toDouble() + 6,
            barColor: randomColor());
      }),
    );
  }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(animDuration + const Duration(milliseconds: 50));
    if (!widget._weeklyIncome.isInitialized) {
      refreshState();
    }
  }

  Color randomColor() => widget.availableColors[Random().nextInt(widget.availableColors.length)];
}