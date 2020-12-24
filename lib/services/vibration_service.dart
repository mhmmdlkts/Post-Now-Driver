import 'package:vibration/vibration.dart';

class VibrationService {

  static vibrateGoOffline() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      await Vibration.vibrate(duration: 1000, amplitude: 128);
    } else {
      await Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 500));
      await Vibration.vibrate();
    }
  }

  static vibrateGoOnline() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      await Vibration.vibrate(pattern: [0, 250, 50, 150]);
    } else {
      await Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 50));
      await Vibration.vibrate();
    }
  }

  static vibrateMessage() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      await Vibration.vibrate(duration: 300);
    } else {
      await Vibration.vibrate();
    }
  }

  static vibrateCancel({n = 1}) async {
    if (n == 0)
      return;
    if (await Vibration.hasCustomVibrationsSupport()) {
      await Vibration.vibrate(duration: 500);
    } else {
      await Vibration.vibrate();
    }
    await Future.delayed(Duration(milliseconds: 1000));
    vibrateCancel(n: n-1);
  }

  static vibrateNewOrder() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      await Vibration.vibrate(pattern: [300, 500]);
    } else {
      await Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 300));
      await Vibration.vibrate();
    }
  }
}