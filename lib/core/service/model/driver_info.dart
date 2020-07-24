import 'package:firebase_database/firebase_database.dart';

class DriverWInfo {
  String key;
  String name;
  String surname;
  String email;
  String phone;
  String address;

  DriverWInfo(this.name, this.surname, this.email, this.phone, this.address);

  DriverWInfo.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    surname = snapshot.value["surname"];
    email = snapshot.value["email"];
    phone = snapshot.value["phone"];
    address = snapshot.value["address"];
  }

  DriverWInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    surname = json['surname'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['surname'] = this.surname;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['address'] = this.address;
    return data;
  }
}