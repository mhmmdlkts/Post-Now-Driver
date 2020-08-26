import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'dart:ui' as ui;

class SigningScreen extends StatefulWidget {
  SigningScreen();

  @override
  _SigningScreen createState() => _SigningScreen();
}

class _SigningScreen extends State<SigningScreen> {
  final signatureFieldKey = GlobalKey<SignatureState>();
  bool check = false;

  Uint8List img;

  _SigningScreen();

  @override
  void initState() {
    super.initState();
    check = false;

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
            signingFieldWidget(),
            RaisedButton(
              onPressed: sign,
              child: Text('SIGNING.SIGN'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.lightBlueAccent,
            ),
            RaisedButton(
              onPressed: clear,
              child: Text('SIGNING.CLEAR'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.redAccent,
            ),
          ],
        ),
      )
    );
  }

  sign() async {
    final sign = signatureFieldKey.currentState;
    final image = await sign.getData();
    var data = await image.toByteData(format: ui.ImageByteFormat.png);
    final encoded = base64.encode(data.buffer.asUint8List());
    Navigator.pop(context, encoded);
  }

  clear() {
    signatureFieldKey.currentState.clear();
  }

  static Image decodeSign(encoded) {
    return Image.memory(base64.decode(encoded).buffer.asUint8List());
  }

  Widget signingFieldWidget() => Container(
    margin: EdgeInsets.only(bottom: 20),
    height: (MediaQuery.of(context).size.width - 40) * 0.55,
    decoration: BoxDecoration(
      border: Border.all(),
    ),
    child: Signature(
      color: Colors.black,// Color of the drawing path
      strokeWidth: 2.4, // with,
      backgroundPainter: null, // Additional custom painter to draw stuff like watermark
      onSign: null, // Callback called on user pan drawing
      key: signatureFieldKey, // key that allow you to provide a GlobalKey that'll let you retrieve the image once user has signed
    ),
  );
}
