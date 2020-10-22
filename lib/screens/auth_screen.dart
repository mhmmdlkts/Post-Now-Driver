import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/dialogs/auth_error_dialog.dart';
import 'package:postnow/models/driver.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/services/legal_service.dart';


class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _firebaseService = AuthService();
  bool _signIn;
  String _email;
  String _name;
  String _surname;
  String _phone;
  String _password;
  AuthErrorDialog _errorField;
  final _boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: Colors.white70,
      border: Border.all(width: 0.4, color: const Color(0x99000000)),
  );
  final _roundedRectangleBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4)
  );
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    _firebaseService.iOSPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            color: Color.fromARGB(255, 41, 171, 226),
            child: Center(
                child: ListView(
                  children: [
                    Form(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(bottom: 10),
                            width: MediaQuery.of(context).size.width*0.6,
                            child: FittedBox(
                                fit:BoxFit.fitWidth,
                                child: Text("APP_NAME".tr(),style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            ),
                          ),
                          Image.asset("assets/postnowdriver_icon.png", width: MediaQuery.of(context).size.width*0.4,),
                          _signIn == null ? _signInOrUpPanel() : (_signIn ? _signInPanel() : _signUpPanel()),
                        ],
                      ),
                    )
                  ],
                )
            )
        ),
        floatingActionButtonLocation: _isInputValid ? FloatingActionButtonLocation.endFloat : FloatingActionButtonLocation.startFloat,
        floatingActionButton: _signIn != null ?(_isInputValid?_getFabNext():_getFabPrev()):null,
      ),
    );
  }

  FloatingActionButton _getFabPrev() => FloatingActionButton(
    backgroundColor: Colors.white,
    child: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.blueAccent,),
      onPressed: () => { setState(() { _signIn = null; }) },
    ),
  );

  FloatingActionButton _getFabNext() => FloatingActionButton(
    backgroundColor: Colors.white,
    child: IconButton(
      icon: Icon(Icons.arrow_forward, color: Colors.blueAccent,),
      onPressed: () => {
        if (_signIn)
          _handleSignInEmail()
        else
          _handleSignUp()
      },
    ),
  );

  Widget _signInOrUpPanel() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: RaisedButton(
            color: Colors.redAccent,
            shape: _roundedRectangleBorder,
            child: Text("LOGIN.SIGN_IN".tr(), style: TextStyle(color: Colors.white),),
            onPressed: () { setState(() { _signIn = true; }); },
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: RaisedButton(
            color: Colors.redAccent,
            shape: _roundedRectangleBorder,
            child: Text("LOGIN.SIGN_UP".tr(), style: TextStyle(color: Colors.white),),
            onPressed: () { setState(() { _signIn = false; }); },
          ),
        ),
      ]
  );

  Widget _signInPanel() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: _boxDecoration,
            child: TextFormField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (String val) {
                _email = val;
                _checkIsValid();
              },
            )
        ),
        Container(height: 10,),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: _boxDecoration,
          child: TextFormField(
            decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
            ),
            obscureText: true,
            onChanged: (String val) {
              _password = val;
              _checkIsValid();
            },
          ),
        ),
      ]
  );

  Widget _signUpPanel() => Column(
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: _boxDecoration,
        child: TextFormField(
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'LOGIN.NAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            _name = val;
            _checkIsValid();
          },
        ),
      ),
      Container(height: 8,),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: _boxDecoration,
        child: TextFormField(
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'LOGIN.SURNAME_FIELD_HINT'.tr()
          ),
          onChanged: (String val) {
            _surname = val;
            _checkIsValid();
          },
        ),
      ),
      Container(height: 8,),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: _boxDecoration,
        child: TextFormField(
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'LOGIN.PHONE_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.phone,
          onChanged: (String val) {
            _phone = val;
            _checkIsValid();
          },
        ),
      ),
      Container(height: 8,),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: _boxDecoration,
        child: TextFormField(
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'LOGIN.EMAIL_FIELD_HINT'.tr()
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (String val) {
            _email = val;
            _checkIsValid();
          },
        ),
      ),
      Container(height: 8,),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: _boxDecoration,
        child: TextFormField(
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'LOGIN.PASSWORD_FIELD_HINT'.tr()
          ),
          obscureText: true,
          onChanged: (String val) {
            _password = val;
            _checkIsValid();
          },
        ),
      ),
      Container(height: 10,),
      FlatButton(
          onPressed: () {
            LegalService.openPrivacyPolicy();
          },
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 50),
          child: Text(
            "LOGIN.AGREE_TERMS_AND_POLICY".tr(),
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,)
      ),
    ],
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

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).child("token").set(await _firebaseService.getToken());

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

    Driver driver = new Driver(
        name: _name,
        surname: _surname,
        email: _email,
        phone: _phone,
        token: await _firebaseService.getToken(),
        isOnline: false
    );

    await FirebaseDatabase.instance.reference().child('drivers').child(user.uid).set(driver.toJson());

    return user;
  }

  void _checkIsValid() {
    RegExp regExpEmail = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    RegExp regExpPhone = new RegExp(
      r"^[+][0-9]{8,12}$",
    );
    setState(() {
      if (_signIn) {
        _isInputValid = regExpEmail.hasMatch(_email) && _password.length >= 3;
      } else {
        _isInputValid = _name.length >= 2 && _surname.length >= 2 && _password.length >= 8 && regExpEmail.hasMatch(_email) && regExpPhone.hasMatch(_phone);
      }
    });
  }
}