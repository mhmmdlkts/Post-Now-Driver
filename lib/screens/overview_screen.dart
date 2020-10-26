import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/services/overview_service.dart';
import 'package:postnow/widgets/weekly_income_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  final int proYearWeekCount = 52; // TODO sometimes 53
  final User _user;
  OverviewService _overviewService;
  PageController _pageController;
  int _chosenWeek;
  double _selectedIncome;

  _OverviewScreen(this._user) {
    _overviewService = OverviewService(_user);
  }

  @override
  void initState() {
    super.initState();
    _chosenWeek = _overviewService.currentWeek();
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
            _initOverview(year: year, week: _chosenWeek);
          },
          itemBuilder: (context, index) {
            return _getContent();
          },
        )
    );
  }
  _getContent() => ListView(
    shrinkWrap: true,
    padding: EdgeInsets.only(left: 8, right: 8, top: 10),
    children: [
      Container(height: 15,),
      Text('OVERVIEW.TH_WEEK'.tr(namedArgs: {'week': _chosenWeek.toString()}), style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
      Container(height: 15,),
      Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: !_isInitialized()?1:0,
            child: Container(child: LinearProgressIndicator(minHeight: 12), padding: EdgeInsets.all(20),)
          ),Opacity(
            opacity: _isInitialized()?1:0,
            child: Text(_overviewService.getTotalIncome().toStringAsFixed(2) + " €", style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
          ),
        ],
      ),
      Opacity(
        opacity: _selectedIncome != null?1:0,
        child: Text(_selectedIncome.toString() + " €", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
      ),
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height/4,
          child: Container(
            padding: EdgeInsets.only(left: 5, bottom: 5),
            child: WeeklyIncomeChart(_overviewService.weeklyIncome, (val) {
              setState(() {
                _selectedIncome = val;
              });
            }),
          )
      ),
      _isInitialized()?Container(
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
      ):Container(),
      _divider(),
      ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (context, index) => _divider(),
        itemCount: _overviewService.getTotalTripsCount(),
        itemBuilder: (BuildContext ctxt, int index) => _getSingleJobWidget(_overviewService.getJob(index)),
      ),
      Container(height: 20,)
    ],
  );

  Widget _divider() => Divider(
    height: 0,
    thickness: 1,
  );

  Widget _getSingleJobWidget(Job j) {
    if (j == null)
      return null;
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DirectJobOverview(_user, j, widget.bitmapDescriptorOrigin, widget.bitmapDescriptorDestination)),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(getReadableFinishDay(j.acceptTime)),
              if (j.status == Status.FINISHED)
                Text(j.price.driverBecomes.toString() + " €")
              else
                Text(j.getStatusMessageKey().tr())
            ],
          ),
        )
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