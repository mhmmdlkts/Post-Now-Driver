import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';
import 'package:postnow/dialogs/custom_alert_dialog.dart';
import 'package:postnow/models/driver_info.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/services/legal_service.dart';
import 'package:postnow/services/settings_service.dart';

import 'contact_form_screen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  SettingsScreen(this.user);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DriverWInfo _info;
  SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(widget.user.uid, _allSaved);
    _settingsService.infoRef.onValue.listen((event) {
      setState(() {
        _info = DriverWInfo.fromSnapshot(event.snapshot);
        _settingsService.accountNameCtrl.text = _info.name;
        _settingsService.accountPhoneCtrl.text = _info.phone;
        _settingsService.accountEmailCtrl.text = _info.email;
        _settingsService.settings = _info.settings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('SETTINGS'.tr()),
      ),
      child: _settingsService.settings == null && false ? CupertinoSettings( items: <Widget>[CupertinoActivityIndicator()]):
      CupertinoSettings(
        items: <Widget>[
          CSHeader('SETTINGS_SCREEN.ACCOUNT.TITLE'.tr()),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountNameCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.NAME_HINT".tr()),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountEmailCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.EMAIL_HINT".tr()),
          CupertinoTextField(readOnly: true, decoration: BoxDecoration( color: Colors.black12), onTap: _showAreYouCantChangeDialog, controller: _settingsService.accountPhoneCtrl, placeholder: "SETTINGS_SCREEN.ACCOUNT.PHONE_HINT".tr()),
          
          CSSpacer(showBorder: false),
          CSButton(CSButtonType.DEFAULT_CENTER, "SETTINGS_SCREEN.SOFTWARE_LICENCES".tr(), (){ LegalService.openLicences();}),
          CSSpacer(showBorder: false),
          CSButton(CSButtonType.DESTRUCTIVE, "SETTINGS_SCREEN.SIGN_OUT".tr(),  (){ AuthService().signOut();})
        ],
      ),
    );
  }

  void _allSaved() {
  }

  _showAreYouCantChangeDialog() async {
    final val = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "WARNING".tr(),
            message: "DIALOGS.SETTINGS.YOU_CANT_CHANGE.MESSAGE".tr(),
            negativeButtonText: "CANCEL".tr(),
            positiveButtonText: "DIALOGS.SETTINGS.YOU_CANT_CHANGE.CONTACT".tr(),
          );
        }
    );
    if (val == null || !val)
      return false;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactFormScreen(widget.user)),
    );
  }
}