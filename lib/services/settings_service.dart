import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:postnow/models/global_settings.dart';

class SettingsService {
  final TextEditingController accountNameCtrl = TextEditingController(text: '');
  final TextEditingController accountPhoneCtrl = TextEditingController(text: '');
  final TextEditingController accountEmailCtrl = TextEditingController(text: '');
  final String uid;
  bool enableCustomAddress = false;
  GlobalSettings settings;
  DatabaseReference driverRef;
  VoidCallback saved;

  SettingsService(this.uid, this.saved) {
    driverRef = FirebaseDatabase.instance.reference().child('drivers').child(uid);
  }

  commitSettings() async {
    await driverRef.child("settings").update(settings.toJson());
    saved.call();
  }
}