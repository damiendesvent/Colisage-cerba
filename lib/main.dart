import 'package:flutter/material.dart';
import 'widgets/welcome_screen.dart';
import 'widgets/log_in_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CerbaTraça',
      initialRoute: '/',
      routes: {
        '/': (context) => const LogInScreen(),
        '/welcome': (context) => const WelcomeScreen(),
      },
    );
  }
}
