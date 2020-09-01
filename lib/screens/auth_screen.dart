import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/decoration/custom_padding.dart';
import 'package:postnow/dialogs/auth_error_dialog.dart';
import 'package:postnow/models/driver.dart';
import 'package:postnow/models/driver_info.dart';
import 'package:postnow/service/auth_service.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _signIn;
  String _email;
  String _name;
  String _surname;
  String _phone;
  String _password;
  AuthErrorDialog _errorField;

  @override
  void initState() {
    super.initState();
    _firebaseService.iOSPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('APP_NAME'.tr()),
          brightness: Brightness.dark,
          leading: _signIn != null ? IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => { setState(() { _signIn = null; }) },
          ) : Container(),
        ),
        body: Center(
            child: _signIn == null ? _signInOrUpPanel() : (_signIn ? _signInPanel() : _signUpPanel())
        ),
      ),
    );
  }

  Widget _signInOrUpPanel() => Padding(
      padding: EdgeInsets.only(right: CustomPadding.authScreenLeftAndRight, left: CustomPadding.authScreenLeftAndRight),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: RaisedButton(
                child: Text("LOGIN.SIGN_IN".tr()),
                onPressed: () { setState(() { _signIn = true; }); },
              ),
            ),
            SizedBox(
                width: double.infinity,
                child:
                RaisedButton(
                  child: Text("LOGIN.SIGN_UP".tr()),
                  onPressed: () { setState(() { _signIn = false; }); },
                )
            )
          ]
      )
  );

  Widget _signInPanel() => Padding(
      padding: EdgeInsets.only(right: CustomPadding.authScreenLeftAndRight, left: CustomPadding.authScreenLeftAndRight),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                  labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (String val) {
                _email = val;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                  labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
              ),
              obscureText: true,
              onChanged: (String val) {
                _password = val;
              },
            ),

            SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  child: Text("LOGIN.SIGN_IN".tr()),
                  onPressed: _handleSignInEmail,
                )
            )
          ]
      )
  );

  Widget _signUpPanel() => ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(right: CustomPadding.authScreenLeftAndRight, left: CustomPadding.authScreenLeftAndRight),
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.NAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            _name = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.SURNAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            _surname = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.PHONE_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.phone,
          onChanged: (String val) {
            _phone = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            _email = val;
          },
        ),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
          ),
          obscureText: true,
          onChanged: (String val) {
            _password = val;
          },
        ),
        SizedBox(
            width: double.infinity,
            child: RaisedButton(
              child: Text("LOGIN.SIGN_UP".tr()),
              onPressed: _handleSignUp,
            )
        )
      ]
  );

  Future<User> _handleSignInEmail() async {
    _errorField = null;
    UserCredential result = await _firebaseService.getAuth().signInWithEmailAndPassword(email: _email, password: _password).catchError(_signUpError);

    if (_errorField != null)
      return null;

    final User user = result.user;

    assert(user != null);
    String token = await user.getIdToken();
    assert(token != null);

    final User currentUser = _firebaseService.getAuth().currentUser;
    assert(user.uid == currentUser.uid);

    print('signInEmail succeeded: $user');

    Driver driver = new Driver(token: await _firebaseService.getToken());

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).update(driver.toJson());

    return user;
  }

  _signUpError(error) {
    setState(() {
      _errorField = new AuthErrorDialog(error);
    });
    _errorField.getAlertDialog(context);
  }

  Future<User> _handleSignUp() async {

    _errorField = null;
    UserCredential result = await _firebaseService.getAuth().createUserWithEmailAndPassword(email: _email, password: _password).catchError(_signUpError);
    if (_errorField != null)
      return null;

    assert (result != null);

    final User user = result.user;

    assert (user != null);

    String token = user.uid;
    assert (token != null);

    print(user);

    Driver driver = new Driver(name : _name, token: await _firebaseService.getToken(), isOnline: false);
    DriverWInfo driverInfo = new DriverWInfo(_name, _surname, _email, _phone, null);

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).set(driver.toJson());
    await FirebaseDatabase.instance.reference().child('drivers_info').child(user.uid).set(driverInfo.toJson());

    return user;
  }
}