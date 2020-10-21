import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;

class GlobalSettings {
  String langCode;

  GlobalSettings({this.langCode}) {
    if (langCode == null)
      langCode = ui.window.locale.languageCode;
  }

  GlobalSettings.fromSnapshot(DataSnapshot snapshot) {
    langCode = snapshot.value["lang"];
  }

  GlobalSettings.fromJson(Map json) {
    langCode = json["lang"];
  }

  Map<String, dynamic> toJson() => {
    "lang": langCode
  };
}