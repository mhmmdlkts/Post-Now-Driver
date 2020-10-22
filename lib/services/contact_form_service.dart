import 'package:cloud_firestore/cloud_firestore.dart' as cloud;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:package_info/package_info.dart';
import 'package:postnow/models/driver.dart';

class ContactFormService {
  final cloud.Query query = cloud.FirebaseFirestore.instance.collection('contact');
  final batch = cloud.FirebaseFirestore.instance.batch();
  final cloud.FirebaseFirestore _firestore = cloud.FirebaseFirestore.instance;
  final User user;
  String phone;
  String name;
  DatabaseReference _usersRef;

  ContactFormService(this.user) {
    _usersRef = FirebaseDatabase.instance.reference().child('drivers').child(user.uid);
  }

  Future<void> init() async {
    await _usersRef.once().then((DataSnapshot snapshot){
      Driver me = Driver.fromSnapshot(snapshot);
      phone = me.phone;
      name = me.name;
    });
  }

  Future<void> createRequest({name, email, phone, subject, content}) async {
    final cloud.DocumentReference postRef = _firestore.collection('contact').doc();
    cloud.WriteBatch writeBatch = _firestore.batch();

    writeBatch.set(postRef, {
      'uid' : user.uid,
      'app_package' : (await PackageInfo.fromPlatform()).packageName,
      'name' : name,
      'email' : email,
      'phone' : phone,
      'time' : DateTime.now(),
      'subject' : subject,
      'content' : content,
    });
    await writeBatch.commit();
    await Future.delayed(Duration(milliseconds: 300));
  }
}