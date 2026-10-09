import 'package:flutter/material.dart';

import 'pages/auth/login_page.dart';

void main() {
  runApp(const TwfoodApp());
}

class TwfoodApp extends StatelessWidget {
  const TwfoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TWFOOD',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const LoginPage(),
    );
  }
}
