import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/user_provider.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Multiplication Master',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue).copyWith(
              brightness: Brightness.light,
              surface: Colors.white,
              background: Colors.grey.shade50,
            ),
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).copyWith(
              surface: Colors.black,
              background: Colors.grey.shade900,
            ),
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
