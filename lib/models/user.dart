import 'package:firebase_database/firebase_database.dart';

class User {
  String key;
  String name;
  String phone;
  String email;
  String languageCode;
  String token;

  User({this.name, this.phone, this.token, this.email, this.languageCode});

  User.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    phone = snapshot.value["phone"];
    email = snapshot.value["email"];
    token = snapshot.value["token"];
    languageCode = snapshot.value["lang"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (name != null) data['name'] = this.name;
    if (phone != null) data['phone'] = this.phone;
    if (email != null) data['email'] = this.email;
    if (token != null) data['token'] = this.token;
    if (languageCode != null) data['lang'] = this.languageCode;
    return data;
  }
}