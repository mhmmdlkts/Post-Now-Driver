import 'package:postnow/enums/days_enum.dart';
import 'package:postnow/models/daily_income.dart';
import 'package:postnow/models/job.dart';

class WeeklyIncome {
  final List<DailyIncome> dailyIncomes = List(7);
  final List<Job> jobs = List();
  bool isInitialized = false;

  WeeklyIncome() {
    reset();
  }

  void reset() {
    jobs.clear();
    dailyIncomes[0] = DailyIncome(Days.MONDAY);
    dailyIncomes[1] = DailyIncome(Days.TUESDAY);
    dailyIncomes[2] = DailyIncome(Days.WEDNESDAY);
    dailyIncomes[3] = DailyIncome(Days.THURSDAY);
    dailyIncomes[4] = DailyIncome(Days.FRIDAY);
    dailyIncomes[5] = DailyIncome(Days.SATURDAY);
    dailyIncomes[6] = DailyIncome(Days.SUNDAY);
  }

  void addJob(Job job) { // TODO where all do you use -1 for weekday
    dailyIncomes[job.finishTime.weekday-1].income += job.price;
    jobs.add(job);
  }

  double getTotalIncome() {
    double income = 0;
    dailyIncomes.forEach((element) {income += element.income;});
    return income;
  }

  String getTotalDriveTime() {
    Duration driveTime = Duration();
    jobs.forEach((element) {driveTime = Duration(milliseconds: driveTime.inMilliseconds + element.getDriveTime().inMilliseconds);});
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(driveTime.inMinutes.remainder(60));
    return "${twoDigits(driveTime.inHours)}:$twoDigitMinutes";
  }

  int getTotalTripsCount() {
    return jobs.length;
  }
  
  DailyIncome monday() => dailyIncomes[0];
  DailyIncome tuesday() => dailyIncomes[1];
  DailyIncome wednesday() => dailyIncomes[2];
  DailyIncome thursday() => dailyIncomes[3];
  DailyIncome friday() => dailyIncomes[4];
  DailyIncome saturday() => dailyIncomes[5];
  DailyIncome sunday() => dailyIncomes[6];

  Job getJob(int index) {
    if (jobs.isEmpty || index >= jobs.length)
      return null;
    return jobs[index];
  }
}