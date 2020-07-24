import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/core/service/model/driver.dart';
import 'package:postnow/core/service/model/driver_info.dart';

import 'core/service/firebase_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Now Driver',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FirebaseService().handleAuth(),
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
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static const double padding = 20.0;
  bool signIn;
  String email;
  String name;
  String surname;
  String phone;
  String password;
  ErrorField errorField;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Post Now Driver"),
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

  Widget signInPanel() => Padding(
    padding: EdgeInsets.only(right: padding, left: padding),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
              labelText: 'E-posta adressinizi giriniz'
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            email = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'Sifrenizi Girin'
          ),
          obscureText: true,
          onChanged: (String val) {
            password = val;
          },
        ),

        SizedBox(
            width: double.infinity,
            child: RaisedButton(
              child: Text("Giris Yap"),
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
              labelText: 'Isminizi Girin'
          ),
          onChanged: (String val) {
            name = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'Soyisminizi Girin'
          ),
          onChanged: (String val) {
            surname = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'Telefon Numaranizi Girin'
          ),
          keyboardType: TextInputType.phone,
          onChanged: (String val) {
            phone = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'E-posta adressinizi giriniz'
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            email = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'Sifrenizi Girin'
          ),
          obscureText: true,
          onChanged: (String val) {
            password = val;
          },
        ),
        SizedBox(
        width: double.infinity,
        child: RaisedButton(
            child: Text("Üye Ol"),
            onPressed: () {
              handleSignUp();
            },
          )
        )
      ]
  );

  Future<FirebaseUser> handleSignInEmail() async {
    AuthResult result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final FirebaseUser user = result.user;

    assert(user != null);
    IdTokenResult token = await user.getIdToken();
    assert(token != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    print('signInEmail succeeded: $user');

    Driver driver = new Driver(token: await getPushToken());

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).update(driver.toJson());

    return user;
  }

  Future<String> getPushToken() {
    return _firebaseMessaging.getToken();
  }

  signUpError(error) {
    setState(() {
      errorField = new ErrorField(error);
    });
    errorField.getAlertDialog(context);
  }

  Future<FirebaseUser> handleSignUp() async {
    print("user");
    errorField = null;
    AuthResult result = await _auth.createUserWithEmailAndPassword(email: email, password: password).catchError(signUpError);
    if (errorField != null)
      return null;

    assert (result != null);

    final FirebaseUser user = result.user;

    assert (user != null);

    IdTokenResult token = await user.getIdToken();
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
            child: Text("Giris Yap"),
            onPressed: () { setState(() { signIn = true; }); },
          ),
        ),
        SizedBox(
        width: double.infinity,
        child:
          RaisedButton(
            child: Text("Üye Ol"),
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
        errorMessage = "Your email address appears to be malformed.";
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      case "ERROR_WRONG_PASSWORD":
        errorMessage = "Your password is wrong.";
        errorPoint = ErrorPoint.SIGN_IN_PASSWORD;
        break;
      case "ERROR_USER_NOT_FOUND":
        errorMessage = "User with this email doesn't exist.";
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_USER_DISABLED":
        errorMessage = "User with this email has been disabled.";
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_TOO_MANY_REQUESTS":
        errorMessage = "Too many requests. Try again later.";
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
        errorMessage = "Signing in with Email and Password is not enabled.";
        break;
      case "ERROR_EMAIL_ALREADY_IN_USE":
        errorMessage = "The email address is already in use by another account.";
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      default:
        errorMessage = "An undefined Error happened.";
    }
  }

  getAlertDialog(context) {

    // set up the button
    Widget okButton = FlatButton(
      child: Text("Tamam"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialo
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Hata"),
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