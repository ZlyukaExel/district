import 'package:district/home/home_page.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'district',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 200, 200, 200),
      ),
      home: const HomePage(),
    );
  }
}
