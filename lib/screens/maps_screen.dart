import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/Dialogs/job_request_dialog.dart';
import 'package:map_launcher/map_launcher.dart' as maps;
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/enums/online_status_enum.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/signing_screen.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/screens/slpash_screen.dart';
import 'package:postnow/service/maps_service.dart';
import 'package:postnow/service/auth_service.dart';
import 'package:postnow/enums/menu_typ_enum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postnow/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:postnow/service/overview_service.dart';
import 'package:screen/screen.dart';
import 'chat_screen.dart';
import 'dart:async';

class MapsScreen extends StatefulWidget {
  final User user;
  MapsScreen(this.user);

  @override
  _MapsScreenState createState() => _MapsScreenState(user);
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final Set _markers = new Set<Marker>();
  final User _user;
  bool _isInitialized = false;
  int _initCount = 0;
  int _initDone = 0;
  MapsService _mapsService;
  OverviewService _overviewService;
  BuildContext _jobDialogCtx;
  bool _isZoomed = false;
  bool _locationFocused = true;
  BitmapDescriptor _packageLocationIcon;
  OnlineStatus _onlineStatus = OnlineStatus.OFFLINE;
  GoogleMapController _mapController;
  MenuTyp _menuTyp;
  Position _myPosition;
  Job _job;

  _MapsScreenState(this._user) {
    _mapsService = MapsService(_user.uid);
    _overviewService = OverviewService(_user);
  }

  @override
  void initState() {
    _initCount++;
    super.initState();
    Screen.keepOn(true);
    WidgetsBinding.instance.addObserver(this);

    _initCount++;
    _overviewService.initCompletedJobs().then((value) => {
      nextInitializeDone('0')
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => {
      _packageLocationIcon = BitmapDescriptor.fromBytes(value),
      nextInitializeDone('1')
    });
    _getMyPosition();
    _menuTyp = MenuTyp.WAITING;

    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onResume: $message');
      switch (message["typ"]) {
        case "jobRequest":
          _showJobRequestDialog(Address.fromJson(json.decode(message["originAddress"])));
          break;
        case "message":
          _showMessageToast(message["key"], message["name"], message["message"]);
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


    _initCount++;
    _mapsService.jobsRef.once().then((DataSnapshot snapshot){
      if (snapshot.value != null) {
        snapshot.value.forEach((key, values) {
          Job j = Job.fromJson(values, key: key);
          if (j.isJobForMe(_user.uid) && !j.isJobAccepted()) { // TODO remove the for each
            _setJob(j);
          }
        });
      }
      nextInitializeDone('2');
    });

    _mapsService.jobsRef.onChildChanged.listen((Event e) {
      print('eee');
      Job j = Job.fromSnapshot(e.snapshot);
      _onJobsDataChanged(j);
    });
    _mapsService.driverRef.child(_user.uid).child("isOnline").onValue.listen(_onOnlineStatusChanged);

    _initCount++;
    _setJobIfExist().then((value) => {
      nextInitializeDone('3')
    });

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(_onPositionChanged);
    nextInitializeDone('4');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _content(),
        _isInitialized ? Container() : SplashScreen(),
      ],
    );
  }

  Widget _content() => new OKToast(
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
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    onCameraMoveStarted: () => {
                      setState(() {
                        _locationFocused = _locationFocused == null;
                      })
                    },
                  ),
                ),
                getBottomMenu(),
                getTopIncomePanel(),
              ],
            alignment: Alignment.center,
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
                  title: Text('MAPS.SIDE_MENU.OVERVIEW'.tr()),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OverviewScreen(_user))
                    );
                  },
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
          floatingActionButton: _getFloatingButton()
      )
  );

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    var data = new Map<String, String>();
    data['status'] = state.toString();
    data['time'] = DateTime.now().toString();
    _mapsService.driverRef.child(_user.uid).child("appStatus").update(data);
  }

  nextInitializeDone(String code) {
    // print(code);
    _initDone++;
    if (_initCount == _initDone) {
      _getMyPosition().then((value) => {
        _mapController.moveCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(value.latitude, value.longitude), zoom: 13)
        )),
        Future.delayed(Duration(milliseconds: 500), () =>
            setState((){
              _isInitialized = true;
            })
        )
      });
    }
  }
  
  _onPositionChanged(Position position) {
    setMyPosition(position);
    if (_locationFocused)
      _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
    if (_onlineStatus == OnlineStatus.ONLINE)
      _mapsService.sendMyLocToDB(_myPosition);
    if (_job != null && _isInRange(_job.getOrigin())) {
      setState(() {
        _menuTyp = MenuTyp.IN_ORIGIN_RANGE;
      });
    }
  }

  _onOnlineStatusChanged(Event event) {
    OnlineStatus status = _mapsService.boolToOnlineStatus(event.snapshot.value);
    if (_onlineStatus != status) {
      _onlineStatus = status;
      if (mounted) setState(() {});
    }
  }

  changeStatus (OnlineStatus value) {
    if (!_mapsService.sendMyLocToDB(_myPosition)) {
      SnackBar snackBar = SnackBar(
        content: Text("MAPS.NO_LOCATION_INFORMATION_MESSAGE".tr()),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      return;
    }
    _onlineStatus = value;

    setState(() {
      _mapsService.driverRef.child(_user.uid).child("isOnline").set(_mapsService.onlineStatusToBool(value));
    });
  }

  _onJobsDataChanged(Job j) {
    setState(() {
      if (!j.isJobForMe(_user.uid)) {
        _markers.clear();
        _menuTyp = MenuTyp.WAITING;
        return;
      }
      switch (j.status) {
        case Status.WAITING:
          _setJob(j);
          _menuTyp = MenuTyp.JOB_REQUEST;
          break;
        case Status.ON_ROAD:
          _menuTyp = MenuTyp.ON_JOB;
          break;
        case Status.PACKAGE_PICKED:
          _menuTyp = MenuTyp.PACKAGE_PICKED;
          break;
        case Status.FINISHED:
          _menuTyp = MenuTyp.COMPLETED;
          break;
        case Status.CANCELLED:
          break;
      }
    });
  }

  onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  Widget getBottomMenu() {
    switch (_menuTyp) {
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
                    _openMessageScreen(_job.key, _job.name);
                  },
                  child: Text('SEND_MESSAGE'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
                  color: Colors.lightBlueAccent,
                ),
                RaisedButton(
                  onPressed: _takePackage,
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
                _getBoxButton('assets/new_job_box.png', _acceptJob, Colors.transparent)
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
                        title: Text('MAPS.BOTTOM_MENUS.ON_JOB.YOUR_CUSTOMER'.tr(namedArgs: {'name': _job.name})),
                        subtitle: Text((_job.originAddress.hasDoorNumber()?
                        'MAPS.BOTTOM_MENUS.ON_JOB.PACKAGE_ADDRESS_EXTRA_SERVICE':'MAPS.BOTTOM_MENUS.ON_JOB.PACKAGE_ADDRESS')
                            .tr(namedArgs: {'address': _job.getOriginAddress(), 'name': _job.originAddress.doorName})),
                      ),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: Text('SEND_MESSAGE'.tr()),
                            onPressed: () { _openMessageScreen(_job.key, _job.name); },
                          ),
                          FlatButton(
                            child: Text('MAPS.TAKE_PACKAGE'.tr()),
                            onPressed: _takePackage,
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
                        title: Text('MAPS.BOTTOM_MENUS.PACKAGE_PICKED.YOUR_CUSTOMER'.tr(namedArgs: {'name': _job.name})),
                        subtitle:
                        Text((_job.destinationAddress.hasDoorNumber()?
                            'MAPS.BOTTOM_MENUS.PACKAGE_PICKED.PACKAGE_ADDRESS_EXTRA_SERVICE':'MAPS.BOTTOM_MENUS.PACKAGE_PICKED.PACKAGE_ADDRESS')
                            .tr(namedArgs: {'address': _job.getDestinationAddress(), 'name': _job.destinationAddress.doorName})),
                      ),
                      (_job.sign != null) ?
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                        ],
                      ): Container(),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: Text('MAPS.BOTTOM_MENUS.PACKAGE_PICKED.LET_HIM_SIGNING'.tr(namedArgs: {'name': _job.destinationAddress.doorName})),
                            onPressed: _openSignScreen,
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
                            onPressed: _clearJob,
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

  _launchNavigation(Job job) async {
    final availableMaps = await maps.MapLauncher.installedMaps;
    print(availableMaps);

    LatLng currentTarget = _menuTyp == MenuTyp.PACKAGE_PICKED? job.getDestination() : job.getOrigin();

    if (await maps.MapLauncher.isMapAvailable(maps.MapType.google) && currentTarget != null) {
      await maps.MapLauncher.launchMap(
        description: job.getOriginAddress(),
        mapType: maps.MapType.google,
        coords: maps.Coords(currentTarget.latitude, currentTarget.longitude),
        title: job.name,
      );
    }
  }

  Widget getTopIncomePanel() => Positioned(
      top: 25,
      child: Opacity(
        opacity: 0.9,
        child: FlatButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OverviewScreen(_user))
            );
          },
          shape: new RoundedRectangleBorder(side: BorderSide(
              color: Colors.black,
              width: 1,
              style: BorderStyle.solid
          ), borderRadius: new BorderRadius.circular(25.0)),
          color: Colors.green,

          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Text(_overviewService.getIncomeOfToday().toString() + " €", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20),),
          ),
        ),
      )
  );

  Widget goOnlineOfflineMenu() => Positioned(
      bottom: 0,
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height/4,
          child: Column(
              children: <Widget>[
                _onlineStatus == OnlineStatus.OFFLINE ?
                _getBoxButton('assets/offline_box.png', () {changeStatus(OnlineStatus.ONLINE);}, Colors.transparent):
                _getBoxButton('assets/online_box.png', () {changeStatus(OnlineStatus.OFFLINE);}, Colors.transparent),
              ]
          )
      )
  );

  Future<Position> _getMyPosition() async {
    if (_myPosition != null)
      return _myPosition;

    setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

    Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
      _myPosition = value,
    });

    return _myPosition;
  }
  
  setMyPosition(Position pos) {
    if (!_isZoomed && _mapController != null) {
      _mapsService.setNewCameraPosition(_mapController, new LatLng(pos.latitude, pos.longitude), null, true);
      _isZoomed = true;
    }
    _myPosition = pos;
  }

  FloatingActionButton _getFloatingButton() {
    if (_locationFocused && !_isOnJob())
      return null;
    else if (!_locationFocused)
      return _currentPositionFButton();
    else if (_isOnJob())
      return _navigateFButton();
    return null;
  }

  FloatingActionButton _currentPositionFButton() => FloatingActionButton(
    onPressed: () {
      if (_myPosition == null)
        return;
      _locationFocused = null;
      _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
    },
    child: Icon(Icons.my_location, color: Colors.white,),
    backgroundColor: Colors.lightBlueAccent,
  );

  FloatingActionButton _navigateFButton() => FloatingActionButton(
    onPressed: () {
      _launchNavigation(_job);
    },
    child: Icon(Icons.navigation, color: Colors.white,),
    backgroundColor: Colors.lightGreen,
  );

  bool _isOnJob() {
    return _menuTyp == MenuTyp.ON_JOB;
  }

  bool _isInRange(LatLng point) {
    return _mapsService.coordinateDistance(point, _mapsService.getPositionLatLng(_myPosition)) <= MAX_ARRIVE_DISTANCE_KM;
  }

  _openMessageScreen(key, name) async {
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(key, name, true))
    );
  }

  _openSignScreen() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SigningScreen())
    );
    _completeJob(result);
  }

  _clearJob({withDialog = false}) {
    setState(() {
      if (withDialog) {
        Navigator.pop(_jobDialogCtx);
      }
      _markers.clear();
      _job = null;
      _menuTyp = MenuTyp.WAITING;
    });
  }

  _acceptJob() {
    if (_job == null) {
      print("No Job");
      return;
    }
    _job.setAcceptTime();
    _job.status = Status.ON_ROAD;
    _mapsService.jobsRef.child(_job.key).set(_job.toMap());
    _mapsService.acceptJob(_job.key);
  }

  _takePackage() {
    if (_job == null) {
      print("No Job");
      return;
    }
    _job.setStartTime();
    _job.status = Status.PACKAGE_PICKED;
    _mapsService.jobsRef.child(_job.key).set(_job.toMap());
  }

  _completeJob(sign) {
    if (_job == null) {
      print("No Job");
      return;
    }
    _job.setFinishTime();
    _job.status = Status.FINISHED;
    _job.sign = sign;
    _mapsService.jobsRef.child(_job.key).set(_job.toMap());
    _mapsService.completeJob(_job.key);
  }

  _getBoxButton(String path, onPressed, color) =>
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

  _setJob(Job j) {
    _job = j;
    _markers.add(Marker(
      markerId: MarkerId(j.key),
      position: j.getOrigin(),
      icon: _packageLocationIcon,
      infoWindow: InfoWindow(
        title: j.name,
      ),
    ));
    if (mounted) setState(() {});
  }

  _showJobRequestDialog(Address address) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          _jobDialogCtx = context;
          return JobRequestDialog(
            originAddress: address.getAddress(),
          );
        }
    ).then((value) => {
      if (value == null || !value) {
        _clearJob(withDialog: true)
      } else {
        _acceptJob()
      }
    });
  }

  _showMessageToast(key, name, message) {
    showToastWidget(
        MessageToast(
          message: message,
          name: name,
          onPressed: () {
            _openMessageScreen(key, name);
          },
        ),
        duration: Duration(seconds: 5),
        position: ToastPosition.top,
        handleTouch: false
    );
  }

  Future<void> _setJobIfExist() async {
    _initCount++;
    _mapsService.driverRef.child(_user.uid).child("currentJob").once().then((DataSnapshot snapshot){
      final jobId = snapshot.value;
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).once().then((DataSnapshot snapshot){
          Job j = Job.fromJson(snapshot.value, key: snapshot.key);
          _setJob(j);
          _onJobsDataChanged(j);
          nextInitializeDone('5');
        });
      } else {
        nextInitializeDone('6');
      }
    });
  }
}