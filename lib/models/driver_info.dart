import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/global_settings.dart';

class DriverWInfo {
  String key;
  String name;
  String surname;
  String email;
  String phone;
  String address;
  GlobalSettings settings;

  DriverWInfo(this.name, this.surname, this.email, this.phone, this.address);

  DriverWInfo.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    surname = snapshot.value["surname"];
    email = snapshot.value["email"];
    phone = snapshot.value["phone"];
    address = snapshot.value["address"];
    if (snapshot.value["settings"] != null)
      settings = GlobalSettings.fromJson(snapshot.value["settings"]);
  }

  DriverWInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    surname = json['surname'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    if (json["settings"] != null)
      settings = GlobalSettings.fromJson(json["settings"]);
  }

  Map<String, dynamic> toJson() => {
    'name': this.name,
    'surname': this.surname,
    'email': this.email,
    'phone': this.phone,
    'address': this.address,
    'settings': this.settings.toJson()
  };
}