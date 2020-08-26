import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/driver_info.dart';

import 'core/service/firebase_service.dart';

void main() {
  print('ssss');
  runApp(
    EasyLocalization(
        supportedLocales: [Locale('en', ''), Locale('de', ''), Locale('tr', '')],
        path: 'assets/translations',
        fallbackLocale: Locale('en', ''),
        saveLocale: true,
        useOnlyLangCode: true,
        child: MyApp()
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    /* if (context.locale.languageCode != ui.window.locale.languageCode)
      context.locale = Locale(ui.window.locale.languageCode, ''); */
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'APP_NAME'.tr(),
          theme: ThemeData(
            primarySwatch: Colors.lightBlue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: FirebaseService().handleAuth(snapshot.connectionState),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging _firebaseMessaging;
  static const double padding = 20.0;
  bool signIn;
  String email;
  String name;
  String surname;
  String phone;
  String password;
  ErrorField errorField;
  FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firebaseMessaging = FirebaseMessaging();
    iOS_Permission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('APP_NAME'.tr()),
          brightness: Brightness.dark,
          leading: signIn != null ? IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => { setState(() { signIn = null; }) },
          ) : Container(),
        ),
        body: Center(
          child: signIn == null ? signInOrUpPanel() : (signIn ? signInPanel() : signUpPanel())
        ),
      ),
    );
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  Widget signInPanel() => Padding(
    padding: EdgeInsets.only(right: padding, left: padding),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            email = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
          ),
          obscureText: true,
          onChanged: (String val) {
            password = val;
          },
        ),

        SizedBox(
            width: double.infinity,
            child: RaisedButton(
              child: Text("LOGIN.SIGN_IN".tr()),
              onPressed: () {
                handleSignInEmail();
              },
            )
        )
      ]
    )
  );

  Widget signUpPanel() => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(right: padding, left: padding),
        children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.NAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            name = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.SURNAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            surname = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.PHONE_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.phone,
          onChanged: (String val) {
            phone = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            email = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
          ),
          obscureText: true,
          onChanged: (String val) {
            password = val;
          },
        ),
        SizedBox(
        width: double.infinity,
        child: RaisedButton(
            child: Text("LOGIN.SIGN_UP".tr()),
            onPressed: () {
              handleSignUp();
            },
          )
        )
      ]
  );

  Future<User> handleSignInEmail() async {
    errorField = null;
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password).catchError(signUpError);

    if (errorField != null)
      return null;

    final User user = result.user;

    assert(user != null);
    String token = await user.getIdToken();
    assert(token != null);

    final User currentUser = _auth.currentUser;
    assert(user.uid == currentUser.uid);

    print('signInEmail succeeded: $user');

    Driver driver = new Driver(token: await getPushToken());

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).update(driver.toJson());

    return user;
  }

  Future<String> getPushToken() async {
    return _firebaseMessaging.getToken();
  }

  signUpError(error) {
    setState(() {
      errorField = new ErrorField(error);
    });
    errorField.getAlertDialog(context);
  }

  Future<User> handleSignUp() async {

    errorField = null;
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password).catchError(signUpError);
    if (errorField != null)
      return null;

    assert (result != null);

    final User user = result.user;

    assert (user != null);

    String token = user.uid;
    assert (token != null);

    print(user);

    Driver driver = new Driver(name : name, token: await getPushToken(), isOnline: false);
    DriverWInfo driverInfo = new DriverWInfo(name, surname, email, phone, null);

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).set(driver.toJson());
    await FirebaseDatabase.instance.reference().child('drivers_info').child(user.uid).set(driverInfo.toJson());

    return user;
  }

  Widget signInOrUpPanel() => Padding(
    padding: EdgeInsets.only(right: padding, left: padding),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
        width: double.infinity,
        child: RaisedButton(
            child: Text("LOGIN.SIGN_IN".tr()),
            onPressed: () { setState(() { signIn = true; }); },
          ),
        ),
        SizedBox(
        width: double.infinity,
        child:
          RaisedButton(
            child: Text("LOGIN.SIGN_UP".tr()),
            onPressed: () { setState(() { signIn = false; }); },
          )
        )
      ]
    )
  );
}

enum ErrorPoint {
  SIGN_UP_NAME,
  SIGN_UP_SURNAME,
  SIGN_UP_PHONE,
  SIGN_IN_EMAIL,
  SIGN_UP_EMAIL,
  SIGN_IN_PASSWORD,
  SIGN_UP_PASSWORD,
  SIGN_UP_PASSWORD2,
}

class ErrorField {
  String errorMessage;
  String errorCode;
  ErrorPoint errorPoint;

  ErrorField(error) {
    errorCode = error.code;
    switch (errorCode) {
      case "ERROR_INVALID_EMAIL":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_INVALID_EMAIL".tr();
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      case "ERROR_WRONG_PASSWORD":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_WRONG_PASSWORD".tr();
        errorPoint = ErrorPoint.SIGN_IN_PASSWORD;
        break;
      case "ERROR_USER_NOT_FOUND":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_USER_NOT_FOUND".tr();
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_USER_DISABLED":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_USER_DISABLED".tr();
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_TOO_MANY_REQUESTS":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_TOO_MANY_REQUESTS".tr();
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_OPERATION_NOT_ALLOWED".tr();
        break;
      case "ERROR_EMAIL_ALREADY_IN_USE":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_EMAIL_ALREADY_IN_USE".tr();
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      default:
        errorMessage = error.message;
    }
  }

  getAlertDialog(context) {

    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialo
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("ERROR".tr()),
      content: Text(errorMessage),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}