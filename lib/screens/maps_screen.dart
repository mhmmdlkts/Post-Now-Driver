import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
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
import 'package:postnow/enums/permission_typ_enum.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/models/settings_item.dart';
import 'package:postnow/screens/contact_form_screen.dart';
import 'package:postnow/screens/overview_screen.dart';
import 'package:postnow/screens/settings_screen.dart';
import 'package:postnow/screens/signing_screen.dart';
import 'package:postnow/Dialogs/message_toast.dart';
import 'package:postnow/screens/slpash_screen.dart';
import 'package:postnow/services/global_service.dart';
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
import 'package:postnow/services/permission_service.dart';
import 'package:postnow/services/vibration_service.dart';
import 'package:postnow/widgets/bottom_card.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:screen/screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
import 'chat_screen.dart';
import 'dart:async';

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
  final AudioCache _audioCache = AudioCache();
  AudioPlayer _audioPlayer;
  final User _user;
  ButtonState _onlineOfflineButtonState = ButtonState.success;
  bool _isInitDone = false;
  bool _isInitialized = false;
  int _initCount = 0;
  int _initDone = 0;
  MapsService _mapsService;
  OverviewService _overviewService;
  BuildContext _jobDialogCtx;
  bool _isZoomed = false;
  bool _locationFocused = true;
  BitmapDescriptor _packageLocationIcon, _homeLocationIcon;
  OnlineStatus _onlineStatus = OnlineStatus.OFFLINE;
  GoogleMapController _mapController;
  Marker _packageMarker, _destinationMarker;
  MenuTyp _menuTyp;
  BottomCard _bottomCard, _requestJobBottomCard, _loadingBottomCard;
  StreamSubscription _requestJobListener;
  Position _myPosition;
  String _userPhone;
  final AuthService _firebaseService = AuthService();
  Job _job, _requestJob;

  _MapsScreenState(this._user) {
    _mapsService = MapsService(_user.uid);
    _overviewService = OverviewService(_user);
  }

  @override
  void initState() {
    _initCount++;
    super.initState();
    _firebaseService.setMyToken(_user.uid);

    Screen.keepOn(true);
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 2500)).then((value) {
      if(_initIsDone())
        print("Force init");
    });

    _initCount++;
    _overviewService.initCompletedJobs().then((value) => {
      _nextInitializeDone('0'),
      _overviewService.subscribe(() => setState(() { }) )
    });

    _initCount++;
    initializeDateFormatting().then((value) => {
      _nextInitializeDone('0.0'),
    });

    final markerSize = Platform.isIOS?130:80;

    _initCount++;
    _mapsService.getBytesFromAsset('assets/package_map_marker.png', markerSize).then((value) => {
      _packageLocationIcon = BitmapDescriptor.fromBytes(value),
      _nextInitializeDone('1')
    });

    _initCount++;
    _mapsService.getBytesFromAsset('assets/home_map_marker.png', markerSize).then((value) => { setState((){
      _homeLocationIcon = BitmapDescriptor.fromBytes(value);
      _nextInitializeDone('3');
    })});

    _changeMenuTyp(MenuTyp.WAITING);

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        switch (message["data"]["typ"]) {
          case "jobRequest":
            _showJobRequestDialog(Address.fromJson(json.decode(message["originAddress"])));
            break;
          case "message":
            _showMessageToast(message["key"], message["name"], message["message"]);
            break;
          case "stayOnline":
            _mapsService.updateAppStatus();
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

    _mapsService.driverRef.child(_user.uid).child("isOnline").onValue.listen(_onOnlineStatusChanged);

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

  void _initLoadingBottomCard() {
    _loadingBottomCard = BottomCard(
      key: GlobalKey(),
      maxHeight: 1000, // the reason of the bug is maybe beq of this line :)
      floatingActionButton: _getFloatingButton(),
      showDestinationAddress: false,
      showOriginAddress: false,
      isLoading: true,
      headerText: 'PLEASE_WAIT'.tr(),
      shrinkWrap: false,
      isSwipeButton: false,
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
                    compassEnabled: false,
                    key: _mapKey,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(target: LatLng(0, 0)),
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: _myPosition != null,
                    markers: _createMarker(),
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
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                      image: DecorationImage(image: NetworkImage(_user.photoURL),
                          fit: BoxFit.cover)
                  ),
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.OVERVIEW'.tr()),
                  onTap: _openOverViewScreen,
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.PRIVACY_POLICY'.tr()),
                  onTap: () {
                    LegalService.openPrivacyPolicy(context);
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
                  title: Text('SETTINGS'.tr()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen(_user)),
                    );
                  },
                ),
                ListTile(
                  title: Text('MAPS.SIDE_MENU.SIGN_OUT'.tr(), style: TextStyle(color: Colors.redAccent),),
                  onTap: () {
                    AuthService().signOut();
                  },
                ),
              ],
            ),
          ),
        floatingActionButton: _bottomCard == null && _menuTyp != MenuTyp.LOADING && _requestJobBottomCard == null ? _currentPositionFButton() : null,
      )
  );

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    _mapsService.updateAppStatus();
  }

  void _nextInitializeDone(String code) {
     // print(code + "/" + _initCount.toString());
    _initLoadingBottomCard();
    _initDone++;
    if (_initCount == _initDone) {
      _myJobListener();
      _jobRequestListener();
      _initIsDone();
    }
  }

  bool _initIsDone() {
    if (_isInitDone)
      return false;
    _isInitDone = true;
    _initMyPosition().then((val) => {
      Future.delayed(Duration(milliseconds: 400), () =>
          setState((){
            _isInitialized = true;
          })
      )
    });
    return true;
  }
  
  void _onPositionChanged(Position position) {
    _setMyPosition(position);
    if (_locationFocused)
      _mapsService.setNewCameraPosition(_mapController, LatLng(_myPosition.latitude, _myPosition.longitude), null, true);
    if (_onlineStatus == OnlineStatus.ONLINE)
      _mapsService.sendMyLocToDB(_myPosition);
    if (_job != null && _isInRange(_job.getOrigin())) {
      setState(() {
        // _changeMenuTyp(MenuTyp.IN_ORIGIN_RANGE);
      });
    }
  }

  Set<Marker> _createMarker() {
    Set markers = Set<Marker>();
    if (_packageMarker != null)
      markers.add(_packageMarker);
    if (_destinationMarker != null)
      markers.add(_destinationMarker);
    return markers;
  }

  _onOnlineStatusChanged(Event event) {
    _mapsService.updateAppStatus();
    OnlineStatus status = _mapsService.boolToOnlineStatus(event.snapshot.value);
    final int delayMS = _onlineOfflineButtonState == ButtonState.success?0:800; // TODO Check is first init?
    Future.delayed(Duration(milliseconds: delayMS), () {
      if (mounted) setState(() {
        _onlineOfflineButtonState = ButtonState.idle;
        if (!_isInitialized)
          return;
        if (_onlineStatus == OnlineStatus.ONLINE) {
          _audioCache.play('sounds/positive.mp3');
          VibrationService.vibrateGoOnline();
        } else if (_onlineStatus == OnlineStatus.OFFLINE) {
          _audioCache.play('sounds/negative.mp3');
          VibrationService.vibrateGoOffline();
        }
      });
    });
    if (_onlineStatus != status) {
      _onlineOfflineButtonState = ButtonState.loading;
      if (mounted) setState(() {});
      _onlineStatus = status;
      Future.delayed(Duration(milliseconds: 400), () {
        _onlineOfflineButtonState = ButtonState.idle;
        if (mounted) setState(() {});
      });
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

    _mapsService.driverRef.child(_user.uid).child("isOnline").set(_mapsService.onlineStatusToBool(value));
  }

  _onMyJobChanged(Job j) {
    _audioPlayer?.stop();
    setState(() {
      _addAddressMarker(null, null);
      if (_job.status == Status.PACKAGE_PICKED)
        _addAddressMarker(j.destinationAddress.coordinates, true);
      else if (_job.status == Status.ON_ROAD || _job.status == Status.ACCEPTED)
        _addAddressMarker(j.originAddress.coordinates, false);
      switch (j.status) {
        case Status.WAITING:
          _setJob(j);
          _changeMenuTyp(MenuTyp.JOB_REQUEST);
          _playNewOrderSound("1");
          break;
        case Status.ACCEPTED:
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

  _playNewOrderSound (a) async {
    _audioPlayer?.stop();
    _audioPlayer = await _audioCache.loop('sounds/new_order.mp3');
    while (_requestJobBottomCard != null) {
      await VibrationService.vibrateMessage();
    }
    _audioPlayer?.stop();
  }

  _clearJobRequest() {
    setState(() {
      _requestJobListener?.cancel();
      _requestJobBottomCard = null;
      _audioPlayer?.stop();
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
    if (_requestJobBottomCard != null)
      return _requestJobBottomCard;
    switch (_menuTyp) {
      case MenuTyp.LOADING:
        return _loadingBottomCard;
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
    // final availableMaps = await maps.MapLauncher.installedMaps;

    Address currentTarget = _menuTyp == MenuTyp.PACKAGE_PICKED? job.destinationAddress : job.originAddress;

    if (await maps.MapLauncher.isMapAvailable(maps.MapType.google) && currentTarget != null) {
      await maps.MapLauncher.launchMap(
        description: currentTarget.doorName,
        mapType: maps.MapType.google,
        coords: maps.Coords(currentTarget.coordinates.latitude, currentTarget.coordinates.longitude),
        title: currentTarget.getAddress(),
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
            onTap: _openOverViewScreen,
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

  void _openOverViewScreen () {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OverviewScreen(_user, _homeLocationIcon, _packageLocationIcon))
    );
  }

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
            color: _onlineStatus == OnlineStatus.ONLINE? Colors.blue : Colors.redAccent
        ),
        ButtonState.loading: IconedButton(
            color: _onlineStatus == OnlineStatus.ONLINE? Colors.blue : Colors.redAccent
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

  Future<void> _initMyPosition() async {
    while (await PermissionService.positionIsNotGranted(context, PermissionTypEnum.LOCATION)) {}

    _setMyPosition(await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.low));

    Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) => {
      _myPosition = value,
    });

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator().getPositionStream(locationOptions).listen(_onPositionChanged);

    await _mapController.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_myPosition.latitude, _myPosition.longitude), zoom: 13)
    ));
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
    else if (_isOnJob())
      return _navigateFButton();
    return _currentPositionFButton();
  }

  void _changeMenuTyp(menuTyp, {bool forceRefresh = false}) async {
    if (!forceRefresh && _menuTyp == menuTyp)
      return;
    setState(() {
      _menuTyp = menuTyp;
      _changeBottomCard(_menuTyp);
    });
  }

  void _refreshBottomCard() {
    setState(() {
      _changeMenuTyp(_menuTyp, forceRefresh: true);
    });
  }

  void _changeBottomCard(menuTyp) {
    switch (menuTyp)
    {
      case MenuTyp.ON_JOB:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          centerWidget: _goOnlineOfflineButton(),
          floatingActionButton: _getFloatingButton(),
          showDestinationAddress: true,
          showOriginAddress: true,
          chatName: _job.name,
          showShopListButton: _job.shoppingList != null && _job.shoppingList.isNotEmpty,
          phone: _userPhone,
          showCash: true,
          job: _job,
          mainButtonText: 'MAPS.TAKE_PACKAGE'.tr(),
          onMainButtonPressed: _takePackage,
          isSwipeButton: true,
          settingsDialog: _getSettingsDialog(),
        );
        break;
      case MenuTyp.PLEASE_WAIT:
        _bottomCard = new BottomCard(
          key: GlobalKey(),
          maxHeight: _mapKey.currentContext.size.height,
          floatingActionButton: _getFloatingButton(),
          isLoading: true,
          headerText: 'MAPS.BOTTOM_MENUS.PLEASE_WAIT.PLEASE_WAIT'.tr(),
          shrinkWrap: false,
          showFooter: false,
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
          chatName: _job.name,
          showShopListButton: _job.shoppingList != null && _job.shoppingList.isNotEmpty,
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

  FloatingActionButton _currentPositionFButton() {
    if (_myPosition == null)
      return null;
    return FloatingActionButton(
      heroTag: "current_position_fab",
      onPressed: () {
        if (_myPosition == null)
          return;
        _locationFocused = null;
        _mapsService.setNewCameraPosition(
            _mapController, LatLng(_myPosition.latitude, _myPosition.longitude),
            null, true);
      },
      child: Icon(Icons.my_location, color: Colors.white,),
      backgroundColor: Colors.lightBlueAccent,
    );
  }

  FloatingActionButton _navigateFButton() => FloatingActionButton(
    heroTag: "navigate_fab",
    onPressed: () {
      _launchNavigation(_job);
    },
    child: Icon(Icons.navigation, color: Colors.white,),
    backgroundColor: Colors.lightGreen,
  );

  bool _isOnJob() {
    return _menuTyp == MenuTyp.ON_JOB || _menuTyp == MenuTyp.PACKAGE_PICKED;
  }

  bool _isInRange(LatLng point) {
    return _mapsService.coordinateDistance(point, _mapsService.getPositionLatLng(_myPosition)) <= MAX_ARRIVE_DISTANCE_KM;
  }

  _openMessageScreen(key, name) async {
    bool _isDriverApp = await GlobalService.isDriverApp();
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(key, name, _isDriverApp))
    );
  }

  _openSignScreen() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SigningScreen(_job.destinationAddress.doorName))
    );
    if (result != null)
      _completeJob(result);
  }

  _clearJob({withDialog = false}) {
    setState(() {
      _audioPlayer?.stop();
      _destinationMarker = null;
      _packageMarker = null;
      if (withDialog) {
        Navigator.pop(_jobDialogCtx);
      }
      _job = null;
      _changeMenuTyp(MenuTyp.WAITING);
    });
  }

  _acceptJob(String id) {
    _mapsService.jobsRef.child(id).update({"status": Job.statusToString(Status.ACCEPTED)});
    if (_job == null)
      _changeMenuTyp(MenuTyp.LOADING);
    _clearJobRequest();
    // _mapsService.acceptJob(id);
  }

  _takePackage() async {
    if (_job == null) {
      print("No Job");
      return;
    }
    if (_job.price.toBePaid > 0 && !(await _cashWarnDialog(_job.price.toBePaid)))
      return;
    _mapsService.jobsRef.child(_job.key).update({"status": Job.statusToString(Status.PACKAGE_PICKED)});
  }

  _completeJob(sign) {
    if (_job == null) {
      print("No Job");
      return;
    }
    _mapsService.jobsRef.child(_job.key).update({"status": Job.statusToString(Status.FINISHED), "sign": sign});
  }

  _setJob(Job j) {
    _job = j;
    _getPhoneNumberFromUser();
    if (mounted) setState(() {});
  }

  void _addAddressMarker(LatLng position, bool isDestination) {
    if (isDestination == null) {
      _destinationMarker = null;
      _packageMarker = null;
      return;
    }
    Marker marker = Marker(
      markerId: MarkerId(isDestination?"destination":"package"),
      position: position,
      icon: isDestination?_homeLocationIcon:_packageLocationIcon,
    );
    if (isDestination)
      _destinationMarker = marker;
    else
      _packageMarker = marker;
  }

  _getPhoneNumberFromUser() {
    if (_job == null)
      return;
    _mapsService.getPhoneNumberFromUser(_job).then((value) => {
      _userPhone = value,
      _refreshBottomCard()
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
        _acceptJob(_job.key)
      }
    });
  }

  _showMessageToast(key, name, message) {
    VibrationService.vibrateMessage();
    _audioCache.play('sounds/push_notification.mp3');
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
          _changeMenuTyp(MenuTyp.PLEASE_WAIT);
          _mapsService.cancelJob(_job);
        }
      }, icon: Icons.cancel, color: Colors.white),
      SettingsItem(textKey: "CLOSE", onPressed: () {}, icon: Icons.close, color: Colors.redAccent),
    ]
  );

  Future<void> _jobRequestListener() async {

    _mapsService.driverRef.child(_user.uid).child("jobRequest").onValue.listen((Event e) {
      final jobId = e.snapshot.value;
      if (jobId != null) {
        _requestJobListener = _mapsService.jobsRef.child(jobId.toString()).onValue.listen((Event e){
          Job j = Job.fromSnapshot(e.snapshot);
          setState(() {
            _playNewOrderSound("2");
            _requestJobBottomCard = BottomCard(
              key: GlobalKey(),
              maxHeight: _mapKey.currentContext.size.height,
              floatingActionButton: _getFloatingButton(),
              showDestinationAddress: false,
              showOriginAddress: true,
              job: j,
              headerText: 'DIALOGS.JOB_REQUEST.TITLE'.tr(),
              mainButtonText: 'ACCEPT'.tr(),
              onMainButtonPressed: () {
                _acceptJob(j.key);
              },
              shrinkWrap: false,
              isSwipeButton: false,
            );
          });
        });
      } else {
        _clearJobRequest();
      }
    });
  }

  Future<void> _myJobListener() async {
    _mapsService.driverRef.child(_user.uid).child("jobQueue").onValue.listen((Event e) {
      final val = e.snapshot.value;
      if (val != null && val is List && val.length > 0) {
        final jobId = e.snapshot.value[0];
        _mapsService.jobsRef.child(jobId.toString()).onValue.listen((Event e){
          Job j = Job.fromSnapshot(e.snapshot);
          _setJob(j);
          _onMyJobChanged(j);
        });
      } else {
        _clearJob();
      }
      _getPhoneNumberFromUser();
    });
  }

  Future<bool> _cashWarnDialog(double amount) async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "DIALOGS.CASH_WARN.TITLE".tr(namedArgs: {'cash': amount.toStringAsFixed(2)}),
            message: "DIALOGS.CASH_WARN.MESSAGE".tr(namedArgs: {'cash': amount.toStringAsFixed(2)}),
            negativeButtonText: "NO".tr(),
            positiveButtonText: "YES".tr(),
          );
        }
    );
    if (val == null)
      return false;
    return val;
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

  void _updateAppStatus({AppLifecycleState status}) async {

    /*Map<String, dynamic> map = Map();
    map["time"]= DateTime.now().toString();
    if (status != null)
      map["status"]= status.toString();
    _mapsService.driverRef.child(_user.uid).child("appStatus").update(map);*/
  }

  String _getReadableTimeStamp() {
    final DateFormat formatter = DateFormat(DATE_FORMAT);
    return formatter.format(DateTime.now());
  }
}