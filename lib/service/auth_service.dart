import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postnow/screens/auth_screen.dart';
import 'package:postnow/screens/first_screen.dart';
import 'package:postnow/screens/maps_screen.dart';

class FirebaseService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  handleAuth(connectionState) {
    if (connectionState == ConnectionState.done) {
      return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          return FirstScreen(snapshot);
        },
      );
    }
    return Container();
  }

  signOut() {
    FirebaseAuth.instance.signOut();
  }

  signIn(AuthCredential authCredential) {
    FirebaseAuth.instance.signInWithCredential(authCredential);
  }

  signInWithOTP(smsCode, verId) {
    AuthCredential authCredential = PhoneAuthProvider.credential(
        verificationId: verId, smsCode: smsCode);
    signIn(authCredential);
  }

  FirebaseAuth getAuth() {
    return FirebaseAuth.instance;
  }

  iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  Future<String> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}