import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/color_data.dart';
import 'services/api_service.dart';
import 'ui/intro/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ApiService>(
      create: (_) => ApiService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gift Store',
        theme: ThemeData(primaryColor: primaryColor),
        home: const SplashScreen(),
      ),
    );
  }
}
