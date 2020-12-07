import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:postnow/screens/maps_screen.dart';
import 'package:postnow/screens/slpash_screen.dart';
import 'package:postnow/services/first_screen_service.dart';
import 'package:postnow/services/remote_config_service.dart';
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
    if (needsUpdate??true)
      return SplashScreen();

    if (widget.snapshot.hasData) {
      return MapsScreen(widget.snapshot.data);
    }
    return AuthScreen();
  }

  checkUpdates() async {
    await RemoteConfigService.fetch();
    final onlineVersion = await RemoteConfigService.getBuildVersion();
    final int localVersion = int.parse((await PackageInfo.fromPlatform()).buildNumber);

    setState(() {
      needsUpdate = localVersion < onlineVersion;
    });

    if (needsUpdate)
      _firstScreenService.showUpdateAvailableDialog(context);
  }

}