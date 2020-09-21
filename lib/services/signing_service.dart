import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SigningService {
  Future<String> encodeSign(sign) async {
    final image = await sign.getData();
    var data = await image.toByteData(format: ui.ImageByteFormat.png);
    return base64.encode(data.buffer.asUint8List());
  }

  Image decodeSign(encoded) => Image.memory(base64.decode(encoded).buffer.asUint8List());
}