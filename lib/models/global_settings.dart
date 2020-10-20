import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class GlobalSettings {
  GlobalSettings();

  GlobalSettings.fromSnapshot(DataSnapshot snapshot);

  GlobalSettings.fromJson(Map json);

  Map<String, dynamic> toJson() => {
  };
}