import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/local_repository.dart';
import 'ui/home.dart';

void main() => runApp(const ReencontraApp());

class ReencontraApp extends StatelessWidget {
  const ReencontraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Reencontra · Achados e perdidos',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff176b60),
        primary: const Color(0xff176b60),
        surface: const Color(0xfffcfbf7),
      ),
      scaffoldBackgroundColor: const Color(0xfff5f4ee),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xfffcfbf7)),
    ),
    home: Home(
      repository: () async =>
          LocalListingRepository(await SharedPreferences.getInstance()),
    ),
  );
}
