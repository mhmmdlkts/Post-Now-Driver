import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postnow/enums/online_status_enum.dart';
import 'package:http/http.dart' as http;
import 'package:postnow/environment/global_variables.dart';
import 'dart:ui' as ui;

import 'package:postnow/models/job.dart';


const double MAX_ARRIVE_DISTANCE_KM = 0.1;

class MapsService with WidgetsBindingObserver {
  final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users');
  final DatabaseReference jobsRef = FirebaseDatabase.instance.reference().child('jobs');
  final DatabaseReference jobsChatRef = FirebaseDatabase.instance.reference().child('jobs_chat');
  final DatabaseReference driverRef = FirebaseDatabase.instance.reference().child('drivers');
  final DatabaseReference completedJobs = FirebaseDatabase.instance.reference().child('completed-jobs');
  final String uid;
  MapsService(this.uid);


  bool sendMyLocToDB(myPosition) {
    if (myPosition == null)
      return false;
    var data = new Map<String, double>();
    data['lat'] = myPosition.latitude;
    data['long'] = myPosition.longitude;
    driverRef.child(uid).update(data);
    return true;
  }

  OnlineStatus boolToOnlineStatus(value) {
    switch (value) {
      case true:
        return OnlineStatus.ONLINE;
      case false:
        return OnlineStatus.OFFLINE;
    }
    return OnlineStatus.OFFLINE;
  }

  LatLng getPositionLatLng(pos) {
    return LatLng(pos.latitude, pos.longitude);
  }

  double coordinateDistance(LatLng latLng1, LatLng latLng2) {
    if (latLng1 == null || latLng2 == null)
      return 0.0;
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((latLng2.latitude - latLng1.latitude) * p) / 2 +
        c(latLng1.latitude * p) * c(latLng2.latitude * p) * (1 - c((latLng2.longitude - latLng1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  bool onlineStatusToBool(value) {
    switch (value) {
      case OnlineStatus.ONLINE:
        return true;
      case OnlineStatus.OFFLINE:
        return false;
    }
    return null;
  }

  void setNewCameraPosition(GoogleMapController controller, LatLng first, LatLng second, bool centerFirst) {
    if (first == null || controller == null)
      return;
    CameraUpdate cameraUpdate;
    if (second == null) {
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else if (centerFirst) {
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
    } else {
      cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(target:
          LatLng(
              (first.latitude + second.latitude) / 2,
              (first.longitude + second.longitude) / 2
          ),
              zoom: coordinateDistance(first, second)));

      LatLngBounds bound = _latLngBoundsCalculate(first, second);
      cameraUpdate = CameraUpdate.newLatLngBounds(bound, 70);
    }
    controller.animateCamera(cameraUpdate);
  }

  LatLngBounds _latLngBoundsCalculate(LatLng first, LatLng second) {
    bool check = first.latitude < second.latitude;
    return LatLngBounds(southwest: check ? first : second, northeast: check ? second : first);
  }

  void completeJob(String key, String sign) {
    final url = '${FIREBASE_URL}finishJob?jobId=$key&sign=$sign';
    try {
      http.get(url);
    } catch (e) {
      print(e.message);
    }
  }

  void acceptJob(String key) {
    final url = '${FIREBASE_URL}acceptJob?jobId=$key';
    try {
      http.get(url);
    } catch (e) {
      print(e.message);
    }
  }

  void pickPackage(String key) {
    final url = '${FIREBASE_URL}pickJobPackage?jobId=$key';
    try {
      http.get(url);
    } catch (e) {
      print(e.message);
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  Future<String> getPhoneNumberFromUser(Job j) async {
    String phone;
    await userRef.child(j.userId).child("phone").once().then((value) => {
      phone = value.value
    });
    return phone;
  }

  void cancelJob(Job j) async {
    String url = '${FIREBASE_URL}cancelJob?jobId=${j.key}&requesterId=$uid';

    try {
      print(http.get(url));
    } catch (e) {
      print('Error 45: ' + e.message);
    }
  }

  Future<String> getMapStyle() async {
    return await rootBundle.loadString("assets/map_styles/light_map.json");
  }

  void updateAppStatus() {
    String url = '${FIREBASE_URL}iAmHere?driverId=$uid';
    try {
      http.get(url);
    } catch (e) {
      print('Error 37: ' + e.message);
    }
  }

}