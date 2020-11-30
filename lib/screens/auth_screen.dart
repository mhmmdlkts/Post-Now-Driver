import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/dialogs/auth_error_dialog.dart';
import 'package:postnow/services/auth_service.dart';
import 'package:postnow/services/legal_service.dart';


class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _firebaseService = AuthService();
  final GlobalKey _formKey = new GlobalKey();
  String _email;
  String _password;
  String _errorMessage;
  AuthErrorDialog _errorField;
  final _boxDecoration = BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(30)
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
            color: secondaryPurple,
            child: _content()
        ),
      ),
    );
  }

  Widget _content() => Stack(
    children: [
      Positioned(
        top: 100,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/postnowdriver_icon.png", width: MediaQuery.of(context).size.width*0.4,),
            Container(
                width: MediaQuery.of(context).size.width*0.6,
                child: FittedBox(
                    fit:BoxFit.fitWidth,
                    child: Text("APP_NAME".tr(),style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                )
            ),
          ],
        ),
      ),
      Positioned(
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(padding: EdgeInsets.all(20), child: Text("Get Start...", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),),),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 5, blurRadius: 10)]
                ),
                padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 5),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("LOGIN.TITLE".tr(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
                    Text("LOGIN.SUBTITLE".tr(), style: TextStyle(color: Colors.black54),),
                    Container(height: 20,),
                    Visibility(
                      visible: _errorMessage!=null,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: double.infinity),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 10),
                            child: Text(_errorMessage!=null?_errorMessage:"", style: TextStyle(color: Colors.redAccent),),
                          )
                      ),
                    ),
                    Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("LOGIN.EMAIL_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                            Container(height: 10,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: _boxDecoration,
                              child: TextFormField(
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(Icons.email),
                                  hintText: "LOGIN.EMAIL_FIELD_HINT".tr(),
                                ),
                                onChanged: (val) {
                                  _email = val;
                                  _checkIsValid();
                                },
                              ),
                            ),
                            Container(height: 20,),
                            Text("LOGIN.PASSWORD_FIELD_TITLE".tr(), style: TextStyle(color: Colors.grey, fontSize: 18),),
                            Container(height: 10,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: _boxDecoration,
                              child: TextFormField(
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(Icons.lock),
                                  hintText: "LOGIN.PASSWORD_FIELD_HINT".tr(),
                                ),
                                obscureText: true,
                                onChanged: (val) {
                                  _password = val;
                                  _checkIsValid();
                                },
                              ),
                            ),
                            Container(height: 10,),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: double.infinity),
                              child: FlatButton(
                                  onPressed: () async {
                                    LegalService.openWriteMail();
                                  },
                                  child: Text(
                                    "LOGIN.LOGIN_PROBLEMS".tr(),
                                    style: TextStyle(color: secondaryPurple, fontSize: 20),
                                    textAlign: TextAlign.center,)
                              ),
                            ),
                            Container(height: 3,),
                            ListView(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                ButtonTheme(
                                  height: 56,
                                  child: RaisedButton (
                                    color: secondaryPurple,
                                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                                    child: Text("LOGIN.CONTINUE_BUTTON".tr(), style: TextStyle(color: Colors.white),),
                                    onPressed: !_isInputValid? null:_handleSignInEmail,
                                  ),
                                ),
                              ],
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: double.infinity),
                              child: FlatButton(
                                  onPressed: () async {
                                    LegalService.openRegisterDriver(context);
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text: "LOGIN.DON'T_HAVE_AN_ACCOUNT".tr() + " ",
                                      style: TextStyle(color: Colors.black26),
                                      children: <TextSpan>[
                                        TextSpan(text: 'LOGIN.SIGN_UP'.tr(), style: TextStyle(color: secondaryPurple)),
                                      ],
                                    ),
                                  )
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: double.infinity),
                                child: FlatButton(
                                    onPressed: () async {
                                      LegalService.openPrivacyPolicy(context);
                                    },
                                    child: Text(
                                      "LOGIN.AGREE_TERMS_AND_POLICY".tr(),
                                      style: TextStyle(color: Colors.black26),
                                      textAlign: TextAlign.center,)
                                ),
                              ),
                            )
                          ],
                        )
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
    ],
  );

  Future<User> _handleSignInEmail() async {
    _errorField = null;
    UserCredential result = await _firebaseService.getAuth().signInWithEmailAndPassword(email: _email, password: _password).catchError(_signInError);

    if (_errorField != null)
      return null;

    final User user = result.user;

    assert(user != null);
    String token = await user.getIdToken();
    assert(token != null);

    final User currentUser = _firebaseService.getAuth().currentUser;
    assert(user.uid == currentUser.uid);

    return user;
  }

  _signInError(error) {
    setState(() {
      _errorMessage = error.message;
      //_errorField = new AuthErrorDialog(error);
    });
    //_errorField.getAlertDialog(context);
  }

  void _checkIsValid() {
    RegExp regExpEmail = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    RegExp regExpPhone = new RegExp(
      r"^[+][0-9]{8,12}$",
    );
    setState(() {
      _isInputValid = regExpEmail.hasMatch(_email) && _password.length >= 3;
    });
  }
}