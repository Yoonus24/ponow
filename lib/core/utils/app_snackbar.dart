import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

class AppSnackbar {
  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    int seconds = 3,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: seconds),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  static void showError(BuildContext context, Object error) {
    final message = error is AppException ? error.message : error.toString();

    _show(context, message: message, color: Colors.red);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, color: Colors.green, seconds: 2);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, color: Colors.blue, seconds: 2);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message: message, color: Colors.orange);
  }
}
