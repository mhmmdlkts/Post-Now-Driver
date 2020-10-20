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
  DatabaseReference infoRef;
  VoidCallback saved;

  SettingsService(this.uid, this.saved) {
    infoRef = FirebaseDatabase.instance.reference().child('drivers_info').child(uid);
  }

  commitSettings() async {
    await infoRef.child("settings").update(settings.toJson());
    saved.call();
  }
}