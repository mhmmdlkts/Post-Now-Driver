import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/environment/global_variables.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/models/driver.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:flutter/material.dart';

class FirstScreenService {

  Driver driver;

  Future<void> showUpdateAvailableDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('DIALOGS.UPDATE_AVAILABLE.TITLE'.tr()),
          content: SingleChildScrollView(
            child: Text('DIALOGS.UPDATE_AVAILABLE.BODY'.tr()),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('DIALOGS.UPDATE_AVAILABLE.BUTTON'.tr()),
              onPressed: () {
                StoreRedirect.redirect();
              },
            ),
          ],
        );
      },
    );
  }


  Future<bool> fetchUser(User user, BuildContext context) async {
    if (driver != null)
      return false;
    DataSnapshot result = await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).once();
    driver = Driver.fromSnapshot(result);
    if (!hasPermission())
      showNoAccountDialog(context);
    return true;
  }

  bool hasPermission() => driver?.isActive()??false;

  Future<void> showNoAccountDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('DIALOGS.NO_ACCOUNT.TITLE'.tr()),
          content: SingleChildScrollView(
            child: Text('DIALOGS.NO_ACCOUNT.BODY'.tr()),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('DIALOGS.NO_ACCOUNT.BUTTON'.tr()),
              onPressed: () => exit(0), // TODO first logout
            ),
          ],
        );
      },
    );
  }
}