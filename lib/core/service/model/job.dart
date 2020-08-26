import 'package:firebase_database/firebase_database.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum Vehicle {
  CAR,
  BIKE
}

enum Status {
  WAITING,
  ON_ROAD,
  PACKAGE_PICKED,
  FINISHED,
  CANCELLED
}

class Job {
  String key;
  String driverId;
  String userId;
  String name;
  String pin;
  double price;
  Status status;
  Vehicle vehicle;
  DateTime start_time;
  DateTime accept_time;
  DateTime finish_time;
  LatLng origin;
  LatLng destination;
  String originAddress;
  String destinationAddress;

  Job({this.name, this.userId, this.driverId, this.vehicle, this.origin, this.destination, this.originAddress, this.destinationAddress}) {
    setStartTime();
    status = Status.WAITING;
  }

  setStartTime() {
    start_time = DateTime.now();
  }

  setAcceptTime() {
    accept_time = DateTime.now();
  }

  setFinishTime() {
    finish_time = DateTime.now();
  }

  Job.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    driverId = snapshot.value["driver-id"];
    userId = snapshot.value["user-id"];
    pin = snapshot.value["pin"];
    price = snapshot.value["price"] + 0.0;
    status = stringToStatus(snapshot.value["status"]);
    vehicle = stringToVehicle(snapshot.value["vehicle"]);
    origin = stringToLatLng(snapshot.value["origin"]);
    destination = stringToLatLng(snapshot.value["destination"]);
    originAddress = snapshot.value["origin-address"];
    destinationAddress = snapshot.value["destination-address"];
    start_time = stringToDateTime(snapshot.value["start-time"]);
    accept_time = stringToDateTime(snapshot.value["accept-time"]);
    finish_time = stringToDateTime(snapshot.value["finish-time"]);
  }

  static Status stringToStatus(String status_string) {
    switch (status_string) {
      case "waiting":
        return Status.WAITING;
      case "on_the_road":
        return Status.ON_ROAD;
      case "package_picked":
        return Status.PACKAGE_PICKED;
      case "finished":
        return Status.FINISHED;
      case "no_driver_found":
        return Status.CANCELLED;
    }
    return null;
  }

  static String statusToString(Status status) {
    switch (status) {
      case Status.WAITING:
        return "waiting";
      case Status.ON_ROAD:
        return "on_the_road";
      case Status.PACKAGE_PICKED:
        return "package_picked";
      case Status.FINISHED:
        return "finished";
      case Status.CANCELLED:
        return "no_driver_found";
    }
    return null;
  }

  static Vehicle stringToVehicle(String vehicle_string) {
    switch (vehicle_string) {
      case "car":
        return Vehicle.CAR;
      case "bike":
        return Vehicle.BIKE;
    }
    return null;
  }

  static String vehicleToString(Vehicle vehicle) {
    switch (vehicle) {
      case Vehicle.CAR:
    return "car";
      case Vehicle.BIKE:
    return "bike";
    }
    return null;
  }

  static LatLng stringToLatLng(String latlng_string) {
    if (latlng_string == null)
      return null;
    List<String> latlng = latlng_string.split(",");
    double lat = double.parse(latlng[0]);
    double lng = double.parse(latlng[1]);
    return LatLng(lat, lng);
  }

  static String latLngToString(LatLng latLng) {
    if (latLng == null)
      return null;
    return "${latLng.latitude},${latLng.longitude}";
  }

  static DateTime stringToDateTime(String dateTime_string) {
    if (dateTime_string == null)
      return null;
    return DateTime.parse(dateTime_string);
  }

  static String dateTimeToString(DateTime dateTime) {
    if (dateTime == null)
      return null;
    return dateTime.toString();
  }

  RouteMode getRouteMode() {
    switch (vehicle) {
      case Vehicle.CAR:
        return RouteMode.driving;
      case Vehicle.BIKE:
        return RouteMode.bicycling;
    }
    return null;
  }

  Map toMap() {
    Map toReturn = new Map();
    if (name != null) toReturn['name'] = name;
    if (driverId != null) toReturn['driver-id'] = driverId;
    if (userId != null) toReturn['user-id'] = userId;
    if (pin != null) toReturn['pin'] = pin;
    if (price != null) toReturn['price'] = price;
    if (status != null) toReturn['status'] = statusToString(status);
    if (vehicle != null) toReturn['vehicle'] = vehicleToString(vehicle);
    if (origin != null) toReturn['origin'] = latLngToString(origin);
    if (destination != null) toReturn['destination'] = latLngToString(destination);
    if (originAddress != null) toReturn['origin-address'] = originAddress;
    if (destinationAddress != null) toReturn['destination-address'] = destinationAddress;
    if (start_time != null) toReturn['start-time'] = dateTimeToString(start_time);
    if (accept_time != null) toReturn['accept-time'] = dateTimeToString(accept_time);
    if (finish_time != null) toReturn['finish-time'] = dateTimeToString(finish_time);
    return toReturn;
  }

  @override
  bool operator == (covariant Job other) => key.compareTo(other.key) == 0;

}