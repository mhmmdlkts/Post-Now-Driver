import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

class AuthErrorDialog {
  String errorMessage;
  String errorCode;
  ErrorPoint errorPoint;

  AuthErrorDialog(error) {
    errorCode = error.code;
    switch (errorCode) {
      case "ERROR_INVALID_EMAIL":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_INVALID_EMAIL".tr();
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      case "ERROR_WRONG_PASSWORD":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_WRONG_PASSWORD".tr();
        errorPoint = ErrorPoint.SIGN_IN_PASSWORD;
        break;
      case "ERROR_USER_NOT_FOUND":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_USER_NOT_FOUND".tr();
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_USER_DISABLED":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_USER_DISABLED".tr();
        errorPoint = ErrorPoint.SIGN_IN_EMAIL;
        break;
      case "ERROR_TOO_MANY_REQUESTS":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_TOO_MANY_REQUESTS".tr();
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_OPERATION_NOT_ALLOWED".tr();
        break;
      case "ERROR_EMAIL_ALREADY_IN_USE":
        errorMessage = "LOGIN.ERROR_MESSAGES.ERROR_EMAIL_ALREADY_IN_USE".tr();
        errorPoint = ErrorPoint.SIGN_UP_EMAIL;
        break;
      default:
        errorMessage = error.message;
    }
  }

  getAlertDialog(context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("ERROR".tr()),
      content: Text(errorMessage),
      actions: [ okButton ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}