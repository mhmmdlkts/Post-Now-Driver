import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/service/overview_service.dart';
import 'package:postnow/widgets/weekly_income_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui' as ui;

class OverviewScreen extends StatefulWidget {
  final User user;
  OverviewScreen(this.user);

  @override
  _OverviewScreen createState() => _OverviewScreen(user);
}

class _OverviewScreen extends State<OverviewScreen> {
  final int proYearWeekCount = 52; // TODO sometimes 53
  final User _user;
  OverviewService _overviewService;
  PageController _pageController;
  int _chosenWeek;
  bool _isInitialized = false;

  _OverviewScreen(this._user) {
    _overviewService = OverviewService(_user);
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _chosenWeek = _overviewService.currentWeek();
    print(_chosenWeek);
    _pageController = PageController(initialPage: _chosenWeek);

    _initOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: Text("OVERVIEW.TITLE".tr()),
          centerTitle: false,
          brightness: Brightness.dark,
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            int extraWeek = 0;
              if (index < _chosenWeek)
              extraWeek--;
              if (index < _chosenWeek)
              extraWeek++;
            int year = _pageToYear(index);
            _chosenWeek = _pageToWeek(index);
            print(_chosenWeek);
            _initOverview(year: year, week: _chosenWeek);
          },
          itemBuilder: (context, index) {
            return _getContent();
          },
        )
    );
  }
  _getContent() => ListView(
    padding: EdgeInsets.only(left: 8, right: 8, top: 10),
    children: [
      Container(height: 15,),
      Text('OVERVIEW.TH_WEEK'.tr(namedArgs: {'week': _chosenWeek.toString()}), style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
      Container(height: 15,),
      !_isInitialized? Container(child: CircularProgressIndicator(), padding: EdgeInsets.symmetric(horizontal: 40),):
      Text(_overviewService.getTotalIncome().toString() + " €", style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
      Container(height: 15,),
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height/4,
          child: Container(
            padding: EdgeInsets.only(left: 5, bottom: 5),
            child: WeeklyIncomeChart(_overviewService.weeklyIncome),
          )
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(_overviewService.getTotalTripsCount().toString(), style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
                Text("OVERVIEW.TOTAL_TRIP_COUNT".tr(), style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
            Column(
              children: [
                Text(_overviewService.getTotalDriveTime(), style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
                Text("OVERVIEW.TOTAL_DRIVE_TIME".tr(), style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        itemCount: _overviewService.getTotalTripsCount(),
        itemBuilder: (BuildContext ctxt, int index) => _getSingleJobWidget(_overviewService.getJob(index)),
      )
    ],
  );

  Widget _getSingleJobWidget(Job j) {
    if (j == null)
      return null;
    return Column(
      children: [
        Divider(
          height: 45,
          thickness: 1,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(getReadableFinishDay(j.finishTime)),
              Text(j.price.toString() + " €")
            ],
          ),
        )
      ],
    );
  }

  String getReadableFinishDay(DateTime d) {
    final DateFormat formatter = DateFormat('dd. MMMM, HH:mm');
    return formatter.format(d);
  }

  int _pageToYear(page) {
    return _overviewService.currentYear() + (page/(proYearWeekCount + 1)).floor();
  }

  int _pageToWeek(page) {
    return (page % (proYearWeekCount));
  }

  _initOverview({int year, int week, isNext = false, isPrev = false}) {
    setState(() {
      _isInitialized = false;
    });
    _overviewService.initCompletedJobs(year: year, week: week).then((value) {
      setState(() {
        _isInitialized = true;
      });
    });
  }

}