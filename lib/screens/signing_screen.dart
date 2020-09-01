import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:postnow/service/signing_service.dart';

class SigningScreen extends StatefulWidget {
  SigningScreen();

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
            RaisedButton(
              onPressed: _sign,
              child: Text('SIGNING.SIGN'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.lightBlueAccent,
            ),
            RaisedButton(
              onPressed: _clear,
              child: Text('SIGNING.CLEAR'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.redAccent,
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
