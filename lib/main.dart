import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:postnow/widgets/stateful_wrapper.dart';

import 'service/auth_service.dart';
import 'dart:ui' as ui;

void main() {
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
    return StatefulWrapper(
      onInit: () { context.locale = Locale(ui.window.locale.languageCode, ''); },
      child: FutureBuilder(
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
      )
    );
  }
}