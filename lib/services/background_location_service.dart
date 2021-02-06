import 'dart:async';

import 'package:carp_background_location/carp_background_location.dart';
import 'package:easy_localization/easy_localization.dart';

class BackgroundLocationService {

  LocationManager _locationManager = LocationManager.instance;
  Stream<LocationDto> _dtoStream;
  StreamSubscription<LocationDto> _dtoSubscription;

  start(void onData(LocationDto event)) async {
    await stop();
    _locationManager.interval = 1;
    _locationManager.distanceFilter = 250;
    _locationManager.notificationTitle = 'MAPS.YOU_ARE_ONLINE'.tr();
    _locationManager.notificationMsg = 'MAPS.YOU_ARE_ONLINE'.tr();
    _locationManager.notificationBigMsg = '';
    _dtoStream = _locationManager.dtoStream;
    _dtoSubscription = _dtoStream.listen(onData);

    if (!(await _locationManager.isRunning))
      await _locationManager.start();
  }

  stop() async {
    _dtoSubscription?.cancel();
    if (await _locationManager.isRunning)
      await _locationManager?.stop();
  }
}