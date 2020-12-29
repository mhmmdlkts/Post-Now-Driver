import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/models/daily_income.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/services/overview_service.dart';
import 'package:postnow/widgets/chart_widget.dart';
import 'package:intl/intl.dart';

import 'direct_job_overview_screen.dart';


class OverviewScreen extends StatefulWidget {
  final BitmapDescriptor bitmapDescriptorDestination;
  final BitmapDescriptor bitmapDescriptorOrigin;
  final User user;
  OverviewScreen(this.user, this.bitmapDescriptorDestination, this.bitmapDescriptorOrigin);

  @override
  _OverviewScreen createState() => _OverviewScreen(user);
}

class _OverviewScreen extends State<OverviewScreen> {
  final int proYearWeekCount = 53; // TODO sometimes 52
  final User _user;
  OverviewService _overviewService;
  PageController _pageController;
  int _chosenWeek;
  int _chosenYear;
  DailyIncome _selectedIncome;
  int _maxPage = 52 * 5;
  int _lastWeek;

  _OverviewScreen(this._user) {
    _overviewService = OverviewService(_user);
  }

  @override
  void initState() {
    super.initState();
    _lastWeek = _overviewService.dayOfWeek();
    _chosenWeek = _lastWeek;
    _pageController = PageController(initialPage: _getPageIndex());

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
          itemCount: _maxPage,
          controller: _pageController,
          onPageChanged: (index) {
            _chosenYear = _pageToYear(_pageToReadable(index));
            _chosenWeek = _pageToWeek(_pageToReadable(index));
            _initOverview(year: _chosenYear, week: _chosenWeek);
          },
          itemBuilder: (context, index) {
            return _getContent();
          },
        )
    );
  }

  int _getPageIndex() => _maxPage + _lastWeek - _chosenWeek;
  int _pageToReadable(int page) => _lastWeek + 1 + page - _maxPage;

  _getContent() => ListView(
    shrinkWrap: true,
    padding: EdgeInsets.only(left: 8, right: 8, top: 10),
    children: [
      ChartWidget(_overviewService.weeklyIncome, _chosenWeek, _chosenYear, (val) {
        setState(() {
          _selectedIncome = val;
        });
      }),
      _isInitialized()?Container(
        child: Row(
          children: [
            Flexible(
              flex: 1,
              child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.lightBlue,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Text(_overviewService.getTotalTripsCount().toString(), style: TextStyle(fontSize: 36, color: Colors.white), textAlign: TextAlign.center),
                            Text("OVERVIEW.TOTAL_TRIP_COUNT".tr(), style: TextStyle(fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                  )
              ),
            ),
            Flexible(
              flex: 1,
              child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.lightBlue,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Text(_overviewService.getTotalDriveTime(), style: TextStyle(fontSize: 36, color: Colors.white), textAlign: TextAlign.center),
                            Text("OVERVIEW.TOTAL_DRIVE_TIME".tr(), style: TextStyle(fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                  )
              ),
            ),
          ],
        ),
      ):Container(),
      ListView.builder(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _overviewService.getTotalTripsCount(),
        itemBuilder: (BuildContext ctxt, int index) => _getSingleJobWidget(_overviewService.getJob(index)),
      ),
      Container(height: 20,)
    ],
  );

  Widget _getSingleJobWidget(Job j) {
    if (j == null)
      return null;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.lightBlueAccent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        highlightColor: Colors.lightBlue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DirectJobOverview(_user, j, widget.bitmapDescriptorOrigin, widget.bitmapDescriptorDestination)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(getReadableFinishDay(j.acceptTime), style: TextStyle(color: Colors.white)),
              if (j.status == Status.FINISHED)
                Text(j.price.driverBecomes.toString() + " €", style: TextStyle(color: Colors.white))
              else
                Text(j.getStatusMessageKey().tr(), style: TextStyle(color: Colors.white))
            ],
          )
        )
      )
    );
  }

  String getReadableFinishDay(DateTime d) {
    final DateFormat formatter = DateFormat('dd. MMMM, HH:mm');
    return formatter.format(d);
  }

  int _pageToYear(page) {
    final a = _overviewService.currentYear() + ((page-1)/(proYearWeekCount)).floor();
    return a;
  }

  int _pageToWeek(page) {
    int year = _pageToYear(page);
    int a = page;// % (_overviewService.getYearsWeekCount(year));
    for (int i = _overviewService.currentYear()-1; i >= year; i--) {
      a += _overviewService.getYearsWeekCount(i);
    }
    return a;
  }

  _initOverview({int year, int week, isNext = false, isPrev = false}) {
    setInitialized(false);
    _overviewService.initCompletedJobs(year: year, week: week).then((value) async {
      await Future.delayed(const Duration(milliseconds: 400));
      setInitialized(true);
    });
  }

  setInitialized(bool isInitialized) {
    setState(() {
      _overviewService.weeklyIncome.isInitialized = isInitialized;
    });
  }

  bool _isInitialized() => _overviewService.weeklyIncome.isInitialized;

}