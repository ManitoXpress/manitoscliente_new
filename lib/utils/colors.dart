import 'package:flutter/material.dart';

class CustomColor {
  static const int _customColorValue = 0xFF1A819A;

  static const MaterialColor materialColor =
  MaterialColor(_customColorValue, <int, Color>{
    50: Color(_customColorValue),
    100: Color(_customColorValue),
    200: Color(_customColorValue),
    300: Color(_customColorValue),
    400: Color(_customColorValue),
    500: Color(_customColorValue),
    600: Color(_customColorValue),
    700: Color(_customColorValue),
    800: Color(_customColorValue),
    900: Color(_customColorValue),
  });

  static const Color color = Color(_customColorValue);
}
