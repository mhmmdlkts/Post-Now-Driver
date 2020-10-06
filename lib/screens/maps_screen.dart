import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/Dialogs/job_request_dialog.dart';
import 'package:map_launcher/map_launcher.dart' as maps;
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/dialogs/settings_dialog.dart';
import 'package:postnow/enums/job_status_enum.dart';
import 'package:postnow/enums/online_status_enum.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/models/settings_item.dart';
import 'package:postnow/screens/contact_form_screen.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/signing_screen.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/screens/slpash_screen.dart';
import 'package:postnow/services/legal_service.dart';
import 'package:postnow/services/maps_service.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/enums/menu_typ_enum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postnow/models/job.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:postnow/services/overview_service.dart';
import 'package:postnow/widgets/bottom_card.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:screen/screen.dart';
import 'chat_screen.dart';
import 'dart:async';

import 'legal_menu_screen.dart';
import 'legal_screen.dart';

class MapsScreen extends StatefulWidget {
  final User user;
  MapsScreen(this.user);

  @override
  _MapsScreenState createState() => _MapsScreenState(user);
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _mapKey = GlobalKey();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final LegalService _legalService = LegalService();
  final Set _markers = new Set<Marker>();
  final User _user;
  ButtonState _onlineOfflineButtonState = ButtonState.success;
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
  BottomCard _bottomCard;
  Position _myPosition;
  String _userPhone;
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

    Future.delayed(const Duration(milliseconds: 2500)).then((value) {
      if (_isInitialized)
        return;
      print('Force init');
      setState((){
        _isInitialized = true;
      });
    });

    _initCount++;
    _overviewService.initCompletedJobs().then((value) => {
      _nextInitializeDone('0'),
      _overviewService.subscribe(() => setState(() { }) )
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', 130).then((value) => {
      _packageLocationIcon = BitmapDescriptor.fromBytes(value),
      _nextInitializeDone('1')
    });
    _getMyPosition();
    _changeMenuTyp(MenuTyp.WAITING);

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

    _mapsService.driverRef.child(_user.uid).child("currentJob").onChildChanged.listen((Event e) {
      _getPhoneNumberFromUser();
    });

    _mapsService.driverRef.child(_user.uid).child("isOnline").onValue.listen(_onOnlineStatusChanged);

    _myJobListener();

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(_onPositionChanged);
    _nextInitializeDone('4');
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
                    key: _mapKey,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(target: LatLng(0, 0)),
                    onMapCreated: _onMapCreated,
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
                _getBottomMenu(),
                _getTopIncomePanel(),
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
                  title: Text('MAPS.SIDE_MENU.LEGAL'.tr()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LegalMenu()),
                    );
                  },
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.CONTACT'.tr()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContactFormScreen(_user)),
                    );
                  },
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr(), style: TextStyle(color: Colors.redAccent),),
                  onTap: () {
                    FirebaseService().signOut();
                  },
                ),
              ],
            ),
          ),
        floatingActionButton: _bottomCard == null ? _currentPositionFButton() : null,
      )
  );

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    var data = new Map<String, String>();
    data['status'] = state.toString();
    data['time'] = DateTime.now().toString();
    _mapsService.driverRef.child(_user.uid).child("appStatus").update(data);
  }

  _nextInitializeDone(String code) {
     // print(code + "/" + _initCount.toString());
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
    _setMyPosition(position);
    if (_locationFocused)
      _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
    if (_onlineStatus == OnlineStatus.ONLINE)
      _mapsService.sendMyLocToDB(_myPosition);
    if (_job != null && _isInRange(_job.getOrigin())) {
      setState(() {
        _changeMenuTyp(MenuTyp.IN_ORIGIN_RANGE);
      });
    }
  }

  _onOnlineStatusChanged(Event event) {
    OnlineStatus status = _mapsService.boolToOnlineStatus(event.snapshot.value);
    final int delayMS = _onlineOfflineButtonState == ButtonState.success?0:800; // Check is first init?
    Future.delayed(Duration(milliseconds: delayMS), () {
      if (mounted) setState(() {
        _onlineOfflineButtonState = ButtonState.idle;
      });
    });
    if (_onlineStatus != status) {
      _onlineStatus = status;
      if (mounted) setState(() {});
    }
  }

  _changeStatus ({OnlineStatus value}) {
    if (value == null)
      value = (_onlineStatus == OnlineStatus.ONLINE?OnlineStatus.OFFLINE:OnlineStatus.ONLINE);
    setState(() {
      _onlineOfflineButtonState = ButtonState.loading;
    });
    if (!_mapsService.sendMyLocToDB(_myPosition)) {
      SnackBar snackBar = SnackBar(
        content: Text("MAPS.NO_LOCATION_INFORMATION_MESSAGE".tr()),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);

      setState(() {
        _onlineOfflineButtonState = ButtonState.fail;
      });
      return;
    }
    _onlineStatus = value;

    _mapsService.driverRef.child(_user.uid).child("isOnline").set(_mapsService.onlineStatusToBool(value)).then((value) => {
      setState(() {

      })
    });
  }

  _onMyJobChanged(Job j) {
    setState(() {
      switch (j.status) {
        case Status.WAITING:
          _setJob(j);
          _changeMenuTyp(MenuTyp.JOB_REQUEST);
          break;
        case Status.ON_ROAD:
          _changeMenuTyp(MenuTyp.ON_JOB);
          break;
        case Status.PACKAGE_PICKED:
          _changeMenuTyp(MenuTyp.PACKAGE_PICKED);
          break;
        case Status.FINISHED:
          _changeMenuTyp(MenuTyp.COMPLETED);
          break;
        case Status.CANCELLED:
          break;
      }
    });
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    _mapsService.getMapStyle().then((style) {
      setState(() {
        _mapController.setMapStyle(style);
      });
    });
  }

  Widget _getBottomMenu() {
    switch (_menuTyp) {
      case MenuTyp.WAITING:
        return _goOnlineOfflineMenu();
      case MenuTyp.JOB_REQUEST:
      case MenuTyp.ON_JOB:
      case MenuTyp.IN_ORIGIN_RANGE:
      case MenuTyp.PACKAGE_PICKED:
      case MenuTyp.COMPLETED:
        return _bottomCard;
    }
    return Container();
  }

  _launchNavigation(Job job) async {
    final availableMaps = await maps.MapLauncher.installedMaps;

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

  Widget _getTopIncomePanel() => Positioned(
      top: 25,
      child: Opacity(
        opacity: 1,
        child: Material(
          elevation: 3,
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(25.0)),
          color: Colors.lightBlue,
          child: InkWell(
            borderRadius: BorderRadius.circular(25.0),
            splashColor: Colors.black45,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OverviewScreen(_user))
              );
            },
            child: Center(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Text(_overviewService.getIncomeOfToday().toStringAsFixed(2) + " €", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20),),
              ),
            )
          ),
        ),

      )
  );

  Widget _goOnlineOfflineMenu() => Positioned(
      bottom: 30,
      child: _goOnlineOfflineButton()
  );
  
  Widget _goOnlineOfflineButton() => ProgressButton.icon(
      progressIndicator: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      iconedButtons: {
        ButtonState.idle: IconedButton(
            text: (_onlineStatus == OnlineStatus.ONLINE? "MAPS.YOU_ARE_ONLINE" : "MAPS.YOU_ARE_OFFLINE").tr(),
            icon: Icon(_onlineStatus == OnlineStatus.ONLINE? Icons.location_on : Icons.location_off ,color: Colors.white,),
            color: _onlineStatus == OnlineStatus.ONLINE? Colors.green : Colors.redAccent
        ),
        ButtonState.loading: IconedButton(
            color: _onlineStatus == OnlineStatus.ONLINE? Colors.green : Colors.redAccent
        ),
        ButtonState.fail: IconedButton(
          text: "FAILED".tr(),
          icon: Icon(Icons.cancel,color: Colors.white),
          color: Colors.red.shade300,
        ),
        ButtonState.success: IconedButton( // In first init
            text: "",
            icon: Icon(Icons.cloud_off,color: Colors.white,),
            color: Colors.redAccent
        ),
      },
      onPressed: _changeStatus,
      state: _onlineOfflineButtonState
  );

  Future<Position> _getMyPosition() async {
    if (_myPosition != null)
      return _myPosition;

    _setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

    Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
      _myPosition = value,
    });

    return _myPosition;
  }
  
  _setMyPosition(Position pos) {
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

  void _changeMenuTyp(menuTyp) async {
    setState(() {
      _menuTyp = menuTyp;
      _changeBottomCard(_menuTyp);
    });
  }

  void _changeBottomCard(menuTyp) {
    switch (menuTyp)
    {
      case MenuTyp.JOB_REQUEST:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _getFloatingButton(),
          showDestinationAddress: false,
          showOriginAddress: true,
          messageSendable: false,
          job: _job,
          headerText: 'DIALOGS.JOB_REQUEST.TITLE'.tr(),
          mainButtonText: 'ACCEPT'.tr(),
          onMainButtonPressed: _acceptJob,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      case MenuTyp.ON_JOB:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          centerWidget: _goOnlineOfflineButton(),
          floatingActionButton: _getFloatingButton(),
          showDestinationAddress: true,
          showOriginAddress: true,
          phone: _userPhone,
          job: _job,
          mainButtonText: 'MAPS.TAKE_PACKAGE'.tr(),
          onMainButtonPressed: _takePackage,
          isSwipeButton: true,
          settingsDialog: _getSettingsDialog(),
        );
        break;
      case MenuTyp.IN_ORIGIN_RANGE:
      case MenuTyp.PACKAGE_PICKED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          centerWidget: _goOnlineOfflineButton(),
          floatingActionButton: _getFloatingButton(),
          showDestinationAddress: true,
          showOriginAddress: false,
          phone: _userPhone,
          job: _job,
          mainButtonText: 'MAPS.BOTTOM_MENUS.PACKAGE_PICKED.LET_HIM_SIGNING'.tr(namedArgs: {'name': _job.destinationAddress.doorName}),
          onMainButtonPressed: _openSignScreen,
          isSwipeButton: false,
          settingsDialog: _getSettingsDialog(),
        );
        break;
      case MenuTyp.COMPLETED:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          centerWidget: _goOnlineOfflineButton(),
          floatingActionButton: _getFloatingButton(),
          showDestinationAddress: false,
          showOriginAddress: false,
          messageSendable: false,
          headerText: 'THANKS'.tr(),
          mainButtonText: 'OK'.tr(),
          onMainButtonPressed: _clearJob,
          shrinkWrap: false,
          isSwipeButton: false,
        );
        break;
      default:
        _bottomCard = null;
    }
  }

  FloatingActionButton _currentPositionFButton() => FloatingActionButton(
    heroTag: "current_position_fab",
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
    heroTag: "navigate_fab",
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
        MaterialPageRoute(builder: (context) => SigningScreen("Ali"))
    );
    if (result != null)
      _completeJob(result);
  }

  _clearJob({withDialog = false}) {
    setState(() {
      if (withDialog) {
        Navigator.pop(_jobDialogCtx);
      }
      _markers.clear();
      _job = null;
      _changeMenuTyp(MenuTyp.WAITING);
    });
  }

  _acceptJob() {
    if (_job == null) {
      print("No Job");
      return;
    }
    
    _mapsService.jobsRef.child(_job.key).update({"status": Job.statusToString(Status.ON_ROAD)});
    // _mapsService.acceptJob(_job.key);
  }

  _takePackage() {
    if (_job == null) {
      print("No Job");
      return;
    }
    _mapsService.jobsRef.child(_job.key).update({"status": Job.statusToString(Status.PACKAGE_PICKED)});
  }

  _completeJob(sign) {
    if (_job == null) {
      print("No Job");
      return;
    }
    _mapsService.jobsRef.child(_job.key).update({"status": Job.statusToString(Status.FINISHED), "sign": sign});
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
    _getPhoneNumberFromUser();
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

  _getPhoneNumberFromUser() {
    _mapsService.getPhoneNumberFromUser(_job).then((value) => {
      setState(() {
        _userPhone = value;
      })
    });
  }

  _showJobRequestDialog(Address address) {
    return;
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

  _getSettingsDialog() => SettingsDialog(
      [
        SettingsItem(textKey: "DIALOGS.JOB_SETTINGS.CANCEL_JOB", onPressed: () async {
          if (await _showAreYouSureDialog()) {
            _mapsService.cancelJob(_job);
          }
        }, icon: Icons.cancel, color: Colors.white),
        SettingsItem(textKey: "CLOSE", onPressed: () {}, icon: Icons.close, color: Colors.redAccent),
      ]
  );

  Future<void> _myJobListener() async {
    _mapsService.driverRef.child(_user.uid).child("currentJob").onValue.listen((Event e){
      final jobId = e.snapshot.value;
      print(jobId);
      if (jobId != null) {
        _mapsService.jobsRef.child(jobId.toString()).onValue.listen((Event e){
          Job j = Job.fromSnapshot(e.snapshot);
          _setJob(j);
          _onMyJobChanged(j);
        });
      } else {
        _clearJob();
      }
    });
  }

  Future<bool> _showAreYouSureDialog() async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "WARNING".tr(),
            message: "DIALOGS.ARE_YOU_SURE_CANCEL.CONTENT".tr(),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "ACCEPT".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
  }
}