import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackbar(
      context,
      message,
      bgColor: Colors.green,
      textColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message) {
    _showCustomSnackbar(
      context,
      message,
      bgColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static void _showCustomSnackbar(
    BuildContext context,
    String message, {
    required Color bgColor,
    required Color textColor,
  }) {
    FocusScope.of(context).unfocus();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP_LEFT,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }
}
