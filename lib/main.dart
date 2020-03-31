import 'package:flutter/material.dart';
import 'package:lost_and_found/pages/login_page.dart';
import 'package:lost_and_found/themes/app_theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achados e Perdidos',
      theme: appTheme(),
      home: LoginPage(),
    );
  }
}
