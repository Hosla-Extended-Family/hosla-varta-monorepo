import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';

class SnackBarWidget {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextThemes.bodySmall.copyWith(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
