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
  String toText = '';
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
        alignment: Alignment.center,
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            signingFieldWidget(),
            RaisedButton(
              onPressed: clear,
              child: Text('SIGNING.CLEAR'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.redAccent,
            ),
            RaisedButton(
              onPressed: sign,
              child: Text('SIGNING.SIGN'.tr(), style: TextStyle(fontSize: 20, color: Colors.white)),
              color: Colors.lightBlueAccent,
            ),
            Text(toText),
            (check) ?
            Container(
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.green,
                    image: DecorationImage(
                        image: MemoryImage(img)
                    )
                )) : Container()
          ],
        ),
      )
    );
  }

  sign() async {
    print('ää');
    var image = await signatureFieldKey.currentState.getData();

    a(image);
    print('äää');
  }

  a(image) {
    img = base64Decode(image);
    check = true;
    print(check);
  }

  clear() {
    signatureFieldKey.currentState.clear();
  }

  Widget signingFieldWidget() => Container(
    height: (MediaQuery.of(context).size.width - 40) * 0.5,
    decoration: BoxDecoration(
      border: Border.all(),
    ),
    child: Signature(
      color: Colors.black,// Color of the drawing path
      strokeWidth: 4.0, // with,
      backgroundPainter: null, // Additional custom painter to draw stuff like watermark
      onSign: null, // Callback called on user pan drawing
      key: signatureFieldKey, // key that allow you to provide a GlobalKey that'll let you retrieve the image once user has signed
    ),
  );
}
