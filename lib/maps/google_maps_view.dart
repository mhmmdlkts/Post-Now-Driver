import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_launcher/map_launcher.dart' as maps;
import 'package:oktoast/oktoast.dart';
import 'package:postnow/Dialogs/job_request_dialog.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/chat_screen.dart';
import 'package:postnow/core/service/firebase_service.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/job.dart';
import 'package:easy_localization/easy_localization.dart';

import 'dart:ui' as ui;

import 'package:postnow/signing_screen.dart';

const String GOOGLE_MAPS_URL = "https://www.google.com/maps/search/?api=1&query=";
const String APPLE_MAPS_URL  = "https://maps.apple.com/?sll=";

const double MAX_ARRIVE_DISTANCE_KM = 0.1;
const double EURO_PER_KM = 0.96;
const double EURO_START  = 5.00;

const bool TEST = false;

enum OnlineStatus {
  ONLINE,
  OFFLINE
}

enum MenuTyp {
  WAITING,
  JOB_REQUEST,
  ON_JOB,
  IN_ORIGIN_RANGE,
  PACKAGE_PICKED,
  COMPLETED,
}

class GoogleMapsView extends StatefulWidget {
  final String uid;
  GoogleMapsView(this.uid);

  @override
  _GoogleMapsViewState createState() => _GoogleMapsViewState(uid);
}

class _GoogleMapsViewState extends State<GoogleMapsView> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  BuildContext jobDialogCtx;
  bool locationFocused = true;
  BitmapDescriptor packageLocationIcon, homeLocationIcon;
  List<Driver> drivers = List();
  OnlineStatus onlineStatus = OnlineStatus.OFFLINE;
  Set<Polyline> polylines = {};
  List<LatLng> routeCoords;
  Set markers = Set<Marker>();
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey: "AIzaSyDUr-GnemethAnyLSQZc6YPsT_lFeBXaI8");
  Marker chosenMarker;
  Driver driver;
  DatabaseReference driverRef, jobsRef, jobsChatRef;
  GoogleMapController _controller;
  MenuTyp menuTyp;
  String originAddress, destinationAddress;
  Position myPosition;
  LatLng origin, destination;
  Job job;
  Driver myDriver;
  String uid;


    @override
    void didChangeAppLifecycleState(AppLifecycleState state) async {
      var data = new Map<String, String>();
      data['status'] = state.toString();
      data['time'] = DateTime.now().toString();
      driverRef.child(uid).child("appStatus").update(data);
    }

    void dispose() {
      super.dispose();
    }

    _GoogleMapsViewState(uid) {
      this.uid = uid;
    }

    void onPositionChanged(Position position) {
      setMyPosition(position);
      if (locationFocused)
        setNewCameraPosition(LatLng(myPosition.latitude, myPosition.longitude), null, true);
      if (onlineStatus == OnlineStatus.ONLINE)
        sendMyLocToDB();
      if (job != null && isInRange(job.origin)) {
        setState(() {
          menuTyp = MenuTyp.IN_ORIGIN_RANGE;
        });
      }
    }

    bool sendMyLocToDB() {
      if (myPosition == null)
        return false;
      var data = new Map<String, double>();
      data['lat'] = myPosition.latitude;
      data['long'] = myPosition.longitude;
      driverRef.child(uid).update(data);
      return true;
    }

    double _coordinateDistance(LatLng latLng1, LatLng latLng2) {
      if (latLng1 == null || latLng2 == null)
        return 0.0;
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 -
          c((latLng2.latitude - latLng1.latitude) * p) / 2 +
          c(latLng1.latitude * p) * c(latLng2.latitude * p) * (1 - c((latLng2.longitude - latLng1.longitude) * p)) / 2;
      return 12742 * asin(sqrt(a));
    }

    @override
    void initState() {
      super.initState();
      // Timer.periodic(Duration(seconds: 2), (Timer t) => changeStatus(t.tick%2==0?OnlineStatus.ONLINE:OnlineStatus.OFFLINE));
      WidgetsBinding.instance.addObserver(this);
      getBytesFromAsset('assets/package_map_marker.png', 180).then((value) => {
        packageLocationIcon = BitmapDescriptor.fromBytes(value)
      });
      getBytesFromAsset('assets/home_map_marker.png', 180).then((value) => {
        homeLocationIcon = BitmapDescriptor.fromBytes(value)
      });
      getMyPosition();
      menuTyp = MenuTyp.WAITING;
      jobsRef = FirebaseDatabase.instance.reference().child('jobs');
      jobsChatRef = FirebaseDatabase.instance.reference().child('jobs_chat');
      driverRef = FirebaseDatabase.instance.reference().child('drivers');

      _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
        print('onResume: $message');
        final data = message["data"];
        if (data == null)
          return;
        switch (data["typ"]) {
          case "jobRequest":
            showJobRequestDialog(data["originAddress"]);
            break;
          case "message":
            showMessageToast(data["key"], data["name"], data["message"]);
            break;
        }

        return;
      }, onResume: (Map<String, dynamic> message) {
        print('onResume: $message');
        return;
      }, onLaunch: (Map<String, dynamic> message) {
        print('onLaunch: $message');
        return;
      });


      jobsRef.once().then((DataSnapshot snapshot){
        snapshot.value.forEach((key,values) {
          Job j = Job.fromJson(values, key);
          if (j.isJobForMe(uid) && !j.isJobAccepted()) {
            setJob(j);
          }
        });
      });

      jobsRef.onChildChanged.listen(_onJobsDataChanged);
      driverRef.child(uid).child("isOnline").onValue.listen(_onOnlineStatusChanged);

      var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

      Geolocator().getPositionStream(locationOptions).listen(onPositionChanged);
    }

    _onOnlineStatusChanged(Event event) {
      OnlineStatus status = boolToOnlineStatus(event.snapshot.value);
      if (onlineStatus != status) {
        setState(() {
          onlineStatus = status;
        });
      }
    }

    changeStatus (OnlineStatus value) {
      if (!sendMyLocToDB()) {
        SnackBar snackBar = SnackBar(
          content: Text("MAPS.NO_LOCATION_INFORMATION_MESSAGE".tr()),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
        return;
      }

      setState(() {
        driverRef.child(uid).child("isOnline").set(onlineStatusToBool(value));
        onlineStatus = value;
      });
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

    bool onlineStatusToBool(value) {
      switch (value) {
        case OnlineStatus.ONLINE:
          return true;
        case OnlineStatus.OFFLINE:
          return false;
      }
      return null;
    }

    Future<void> _onJobsDataChanged(Event event) async {
      Job j = Job.fromSnapshot(event.snapshot);
      if (j.isJobForMe(uid)) {
        switch (j.status) {
          case Status.WAITING:
            setJob(j);
            break;
          case Status.ON_ROAD:
            setState(() {
              menuTyp = MenuTyp.ON_JOB;
            });
            break;
          case Status.PACKAGE_PICKED:
            setState(() {
              menuTyp = MenuTyp.PACKAGE_PICKED;
            });
            break;
          case Status.FINISHED:
            setState(() {
              menuTyp = MenuTyp.COMPLETED;
            });
            break;
        }
      } else {
        if(mounted) {
          setState(() {
              markers.clear();
              menuTyp = MenuTyp.WAITING;
          });
        }
      }
    }

    bool isArrived(LatLng destination) {
      return _coordinateDistance(LatLng(myPosition.latitude, myPosition.longitude), destination) <= MAX_ARRIVE_DISTANCE_KM;
    }

    void onMapCreated(GoogleMapController controller) {
      setState(() {
        _controller = controller;
      });
    }

    Future<Uint8List> getBytesFromAsset(String path, int width) async {
      ByteData data = await rootBundle.load(path);
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
    }

    @override
    Widget build(BuildContext context) {
      return OKToast(
          child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
              title: Text("APP_NAME".tr(), style: TextStyle(color: Colors.white),),
              brightness: Brightness.dark,
              iconTheme:  IconThemeData( color: Colors.white)
          ),
          body: Stack(
              children: <Widget>[
                SizedBox(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width, // or use fixed size like 200
                  height: MediaQuery
                      .of(context)
                      .size
                      .height,
                  child: GoogleMap(
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(target: LatLng(0, 0)),
                    onMapCreated: onMapCreated,
                    myLocationEnabled: true,
                    polylines: polylines,
                    markers: markers,
                    myLocationButtonEnabled: false,
                    onCameraMoveStarted: () => {
                      setState(() {
                        locationFocused = locationFocused == null;
                      })
                    },
                  ),
                ),
                getBottomMenu(),
              ]
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Text('SETTINGS'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr()),
                  onTap: () {
                    FirebaseService().signOut();
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: getFloatingButton()
        )
      );
    }

    Widget getBottomMenu() {
      switch (menuTyp) {
        case MenuTyp.WAITING:
          return goOnlineOfflineMenu();
        case MenuTyp.JOB_REQUEST:
          return jobRequestMenu();
        case MenuTyp.ON_JOB:
          return onJobMenu();
        case MenuTyp.IN_ORIGIN_RANGE:
          return inOriginRangeMenu();
        case MenuTyp.PACKAGE_PICKED:
          return packagePickedMenu();
        case MenuTyp.COMPLETED:
          return jobCompletedMenu();
      }
      return Container();
    }

    Widget inOriginRangeMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  RaisedButton(
                    onPressed: () {
                      openMessageScreen(job.key, job.name);
                    },
                    child: Text('SEND_MESSAGE'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                    color: Colors.lightBlueAccent,
                  ),
                  RaisedButton(
                    onPressed: takePackage,
                    child: Text('MAPS.TAKE_PACKAGE'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                    color: Colors.lightBlueAccent,
                  ),
                ]
            )
        )
    );

    Widget jobRequestMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  getBoxButton('assets/new_job_box.png', acceptJob, Colors.transparent)
                ]
            )
        )
    );

    Widget onJobMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.card_giftcard),
                          title: Text('MAPS.BOTTOM_MENUS.ON_JOB.YOUR_CUSTOMER'.tr(namedArgs: {'name': job.name})),
                          subtitle: Text('MAPS.BOTTOM_MENUS.ON_JOB.PACKAGE_ADDRESS'.tr(namedArgs: {'address': job.originAddress})),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('SEND_MESSAGE'.tr()),
                              onPressed: () { openMessageScreen(job.key, job.name); },
                            ),
                            FlatButton(
                              child: Text('MAPS.TAKE_PACKAGE'.tr()),
                              onPressed: takePackage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
            )
        )
    );

    Widget packagePickedMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/3,
            child: true ? Column(
                children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.card_giftcard),
                          title: Text('MAPS.BOTTOM_MENUS.YOUR_CUSTOMER'.tr(namedArgs: {'name': job.name})),
                          subtitle: Text('MAPS.BOTTOM_MENUS.PACKAGE_ADDRESS'.tr(namedArgs: {'address': job.originAddress})),
                        ),
                        (job.sign != null) ?
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                          ],
                        ): Container(),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('MAPS.BOTTOM_MENUS.PACKAGE_PICKED.LET_HIM_SIGNING'.tr()),
                              onPressed: openSignScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
            ): Center(
              child: SingleChildScrollView(
                  child: Container()
              ),
            )
        )
    );

    Widget jobCompletedMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.card_giftcard),
                          title: Text('THANKS'.tr()),
                        ),
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('OK'.tr()),
                              onPressed: clearJob,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
            )
        )
    );

    void launchNavigation(Job job) async {
      final availableMaps = await maps.MapLauncher.installedMaps;
      print(availableMaps);

      if (await maps.MapLauncher.isMapAvailable(maps.MapType.google)) {
        await maps.MapLauncher.launchMap(
          description: job.originAddress,
          mapType: maps.MapType.google,
          coords: maps.Coords(job.origin.latitude, job.origin.longitude), // TODO origin and destination
          title: job.name,
        );
      }
    }

    Widget goOnlineOfflineMenu() => Positioned(
        bottom: 0,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height/4,
            child: Column(
                children: <Widget>[
                  onlineStatus == OnlineStatus.OFFLINE ?
                  getBoxButton('assets/offline_box.png', () {changeStatus(OnlineStatus.ONLINE);}, Colors.transparent):
                  getBoxButton('assets/online_box.png', () {changeStatus(OnlineStatus.OFFLINE);}, Colors.transparent),
                ]
            )
        )
    );

    void setNewCameraPosition(LatLng first, LatLng second, bool centerFirst) {
      if (first == null || _controller == null)
        return;
      CameraUpdate cameraUpdate;
      if (second == null) {
        // firsti ortala, zoom sabit
        cameraUpdate = CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
      } else if (centerFirst) {
        // firsti ortala, secondu da sigdir
        cameraUpdate = CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(first.latitude, first.longitude), zoom: 13));
      } else {
        // first second arasini ortala, ikisini de sigdir
        cameraUpdate = CameraUpdate.newCameraPosition(
            CameraPosition(target:
            LatLng(
                (first.latitude + second.latitude) / 2,
                (first.longitude + second.longitude) / 2
            ),
                zoom: _coordinateDistance(first, second)));

        LatLngBounds bound = _latLngBoundsCalculate(first, second);
        cameraUpdate = CameraUpdate.newLatLngBounds(bound, 70);
      }
      _controller.animateCamera(cameraUpdate);
    }
    LatLngBounds _latLngBoundsCalculate(LatLng first, LatLng second) {
      bool check = first.latitude < second.latitude;
      return LatLngBounds(southwest: check ? first : second, northeast: check ? second : first);
    }

    Future<void> setRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
      routeCoords = List();
      if (TEST) {
        routeCoords.add(origin);
        routeCoords.add(destination);
      } else {
        routeCoords = await googleMapPolyline.getCoordinatesWithLocation(
            origin: origin,
            destination: destination,
            mode: mode);
      }

      setState(() {
        polylines = Set();
        polylines.add(Polyline(
            polylineId: PolylineId("Route"),
            visible: true,
            points: routeCoords,
            width: 2,
            color: Colors.deepPurpleAccent,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
    }

    Future<void> addToRoutePolyline(LatLng origin, LatLng destination, RouteMode mode) async {
      List<LatLng> newRouteCoords = List();

      if (TEST) {
        newRouteCoords.add(origin);
        newRouteCoords.add(destination);
      } else {
        newRouteCoords.addAll(await googleMapPolyline.getCoordinatesWithLocation(
            origin: origin,
            destination: destination,
            mode: mode));
      }

      newRouteCoords.addAll(routeCoords);

      setState(() {
        polylines.add(Polyline(
            polylineId: PolylineId("Route"),
            visible: true,
            points: newRouteCoords,
            width: 2,
            color: Colors.redAccent,
            startCap: Cap.roundCap,
            endCap: Cap.buttCap
        ));
      });
    }

    Future<Position> getMyPosition() async {
      if (myPosition != null)
        return myPosition;

      setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

      Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
        myPosition = value,
      });

      return myPosition;
    }
    bool isZoomed = false;
    void setMyPosition(Position pos) {
      if (!isZoomed && _controller != null) {
        setNewCameraPosition(new LatLng(pos.latitude, pos.longitude), null, true);
        isZoomed = true;
      }
      myPosition = pos;
    }

    FloatingActionButton getFloatingButton() {
      if (locationFocused && !isOnJob())
        return null;
      else if (!locationFocused)
        return currentPositionFButton();
      else if (isOnJob())
        return navigateFButton();
      return null;
    }

    FloatingActionButton currentPositionFButton() => FloatingActionButton(
      onPressed: () {
        if (myPosition == null)
          return;
        locationFocused = null;
        setNewCameraPosition(LatLng(myPosition.latitude, myPosition.longitude), null, true);
      },
      child: Icon(Icons.my_location, color: Colors.white,),
      backgroundColor: Colors.lightBlueAccent,
    );

    FloatingActionButton navigateFButton() => FloatingActionButton(
      onPressed: () {
        launchNavigation(job);
      },
      child: Icon(Icons.navigation, color: Colors.white,),
      backgroundColor: Colors.lightGreen,
    );

    bool isOnJob() {
      return menuTyp == MenuTyp.ON_JOB;
    }

    bool isInRange(LatLng point) {
      return _coordinateDistance(point, LatLng(myPosition.latitude, myPosition.longitude)) <= MAX_ARRIVE_DISTANCE_KM;
    }

    void openMessageScreen(key, name) async {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Chat_Screen(key, name, true))
      );
    }

    void openSignScreen() async {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SigningScreen())
      );
      completeJob(result);
    }

    void clearJob() {
      setState(() {
        Navigator.pop(jobDialogCtx);
        markers.clear();
        routeCoords = null;
        polylines = null;
        myDriver = null;
        originAddress = null;
        destinationAddress = null;
        destination = null;
        origin = null;
        job = null;
        menuTyp = null;
      });
    }

    void acceptJob() {
      job.setAcceptTime();
      job.status = Status.ON_ROAD;
      jobsRef.child(job.key).set(job.toMap());
    }

    void takePackage() {
      job.setStartTime();
      job.status = Status.PACKAGE_PICKED;
      jobsRef.child(job.key).set(job.toMap());
    }

    void completeJob(sign) {
      job.setFinishTime();
      job.status = Status.FINISHED;
      job.sign = sign;
      jobsRef.child(job.key).set(job.toMap());
    }

    getBoxButton(String path, onPressed, color) =>
        FlatButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          color: color,
          child: Container(
            padding: EdgeInsets.only(bottom: 30),
            child: Image.asset(
                path,
                height: MediaQuery.of(context).size.height/6
            ),
          )
        );

  void setJob(Job j) {
    setState(() {
      job = j;
      markers.add(Marker(
        markerId: MarkerId(j.key),
        position: LatLng(j.origin.latitude, j.origin.longitude),
        icon: packageLocationIcon,
        infoWindow: InfoWindow(
          title: j.name,
        ),
      ));
      menuTyp = MenuTyp.JOB_REQUEST;
    });
  }

  showJobRequestDialog(String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        jobDialogCtx = context;
        return JobRequestDialog(
          originAddress: address,
        );
      }
    ).then((value) => {
      if (value == null || !value) {
        clearJob()
      } else {
        acceptJob()
      }
    });
  }

  showMessageToast(key, name, message) {

    showToastWidget(
      MessageToast(
        message: message,
        name: name,
        onPressed: () {
          openMessageScreen(key, name);
        },
      ),
      duration: Duration(seconds: 5),
      position: ToastPosition.top,
      handleTouch: true
    );
  }
}