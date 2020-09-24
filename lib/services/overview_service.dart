import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/job.dart';
import 'package:postnow/models/weekly_income.dart';

class OverviewService {
  final User user;
  final DatabaseReference _jobsRef = FirebaseDatabase.instance.reference().child('completed-jobs');
  final WeeklyIncome weeklyIncome = WeeklyIncome();
  
  OverviewService(this.user);

  subscribe(func, {int year, int week}) {
    if (week == null)
      week = currentWeek();
    if (year == null)
      year = currentYear();
    _jobsRef.child(_getChildKey(year, week)).child(user.uid).onChildAdded.listen((Event e) {
      initCompletedJobs(year: year, week: week).then((value) {
        func.call();
      });
    });
  }
  
  Future<void> initCompletedJobs({int year, int week}) async {
    weeklyIncome.reset();
    await _jobsRef.child(_getChildKey(year, week)).child(user.uid).orderByChild("finished-time").once().then((DataSnapshot snapshot) => {
    weeklyIncome.reset(),
      if (snapshot.value != null) {
        snapshot.value.forEach((key, value) {
          Job j = Job.fromJson(value, key: key);
          weeklyIncome.addJob(j);
        })
      }
    });
  }

  String _getChildKey(int year, int week) {
    if (year == null) 
      year = currentYear();
    if (week == null) 
      week = currentWeek();
    if (week < 0) {
      year--;
      week = 52;
    }
    if (week > 52) {
      year++;
      week = 0;
    }
    return year.toString() + "-" + week.toString();
  }

  int currentDayOfWeek() {
    return DateTime.now().weekday-1;
  }

  int currentYear() {
    return DateTime.now().year;
  }

  int currentWeek() {
    var now = new DateTime.now();

    var dayNr = (now.weekday + 6) % 7;

    var thisMonday = now.subtract(new Duration(days:(dayNr)));
    var thisThursday = thisMonday.add(new Duration(days:3));

    var firstThursday = new DateTime(now.year, DateTime.january, 1);

    if(firstThursday.weekday != (DateTime.thursday))
    {
      firstThursday = new DateTime(now.year, DateTime.january, 1 + ((4 - firstThursday.weekday) + 7) % 7);
    }

    var x = thisThursday.millisecondsSinceEpoch - firstThursday.millisecondsSinceEpoch;
    var weekNumber = x.ceil() / 604800000; // 604800000 = 7 * 24 * 3600 * 1000
    return weekNumber.ceil();
  }

  String getTotalDriveTime() => weeklyIncome.getTotalDriveTime();
  double getTotalIncome() => weeklyIncome.getTotalIncome();
  int getTotalTripsCount() => weeklyIncome.getTotalTripsCount();
  Job getJob(int index) => weeklyIncome.getJob(index);
  double getIncomeOfToday() => weeklyIncome.dailyIncomes[currentDayOfWeek()].income;
}