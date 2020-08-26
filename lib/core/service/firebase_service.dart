import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:postnow/maps/google_maps_view.dart';

import '../../main.dart';

class FirebaseService {
  handleAuth() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return GoogleMapsView(snapshot.data.uid);
        } else {
          return MyHomePage(title: 'APP_NAME'.tr());
        }
      },
    );
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
}