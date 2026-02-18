import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'ui/intro/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadFromPrefs();
  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authProvider});
  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ProxyProvider<AuthProvider, ApiService>(
          update: (_, auth, __) => ApiService(apiKey: auth.apiKey),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gift Store',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
