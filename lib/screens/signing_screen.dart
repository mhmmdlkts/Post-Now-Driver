import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:postnow/decoration/my_colors.dart';
import 'package:postnow/services/signing_service.dart';

class SigningScreen extends StatefulWidget {
  String name;
  SigningScreen(this.name);

  @override
  _SigningScreen createState() => _SigningScreen();
}

class _SigningScreen extends State<SigningScreen> {
  final _signingService = SigningService();
  final _signatureFieldKey = GlobalKey<SignatureState>();

  _SigningScreen();

  @override
  void initState() {
    super.initState();
    print (widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: Text("APP_NAME".tr(), style: TextStyle(color: Colors.white)),iconTheme:  IconThemeData( color: Colors.white),
        brightness: Brightness.dark,
        centerTitle: false,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            _signingFieldWidget(),
            Text('SIGNING.SIGN_TERMS'.tr(namedArgs: {'name': widget.name})),
            Container(height: 20,),
            ButtonTheme(
              minWidth: double.infinity,
              height: 56,
              child: RaisedButton (
                color: primaryBlue,
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                child: Text("SIGNING.SIGN".tr(), style: TextStyle(color: Colors.white, fontSize: 24),),
                onPressed: _sign,
              ),
            ),
            Container(height: 10,),
            ButtonTheme(
              minWidth: double.infinity,
              height: 46,
              child: RaisedButton (
                color: Colors.redAccent,
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                child: Text("SIGNING.CLEAR".tr(), style: TextStyle(color: Colors.white, fontSize: 24),),
                onPressed: _clear,
              ),
            ),
          ],
        ),
      )
    );
  }

  _sign() {
    _signingService.encodeSign(_signatureFieldKey.currentState).then((encoded) => {
      Navigator.pop(context, encoded)
    });
  }

  _clear() {
    _signatureFieldKey.currentState.clear();
  }

  Widget _signingFieldWidget() => Container(
    margin: EdgeInsets.only(bottom: 20),
    height: (MediaQuery.of(context).size.width - 40) * 0.55,
    decoration: BoxDecoration(
      border: Border.all(),
    ),
    child: Signature(
      color: Colors.black,
      strokeWidth: 2.4,
      backgroundPainter: null,
      onSign: null,
      key: _signatureFieldKey,
    ),
  );
}
