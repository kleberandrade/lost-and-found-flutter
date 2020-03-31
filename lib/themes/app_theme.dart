import 'package:flutter/material.dart';

const brightness = Brightness.light;
const primaryColor = Colors.red;
const accentColor = Colors.redAccent;
const backgroundColor = Colors.white;

ThemeData appTheme() {
  return ThemeData(
    brightness: brightness,
    primaryColor: primaryColor,
    accentColor: accentColor,
    scaffoldBackgroundColor: backgroundColor,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
