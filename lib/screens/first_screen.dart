import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:postnow/screens/maps_screen.dart';
import 'package:postnow/screens/slpash_screen.dart';
import 'package:postnow/service/auth_service.dart';
import 'package:postnow/service/first_screen_service.dart';
import 'auth_screen.dart';


class FirstScreen extends StatefulWidget {
  final AsyncSnapshot snapshot;
  FirstScreen(this.snapshot);

  @override
  _FirstScreen createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  final FirstScreenService _firstScreenService = FirstScreenService();
  bool needsUpdate;

  @override
  void initState() {
    super.initState();

    checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    if (needsUpdate == null)
      return SplashScreen();
    if (needsUpdate)
      return SplashScreen();

    if (widget.snapshot.hasData) {
      return MapsScreen(widget.snapshot.data);
    } else {
      return AuthScreen();
    }
  }

  checkUpdates() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();

    final onlineVersion = remoteConfig.getInt(FIREBASE_REMOTE_CONFIG_VERSION_KEY);
    final int localVersion = int.parse((await PackageInfo.fromPlatform()).buildNumber);

    setState(() {
      needsUpdate = localVersion < onlineVersion;
    });

    if (needsUpdate)
      _firstScreenService.showUpdateAvailableDialog(context);
  }

}