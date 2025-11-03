import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/user_provider.dart';
import 'services/auth_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences and Firebase in parallel
  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create theme provider and wait for it to initialize
  final themeProvider = ThemeProvider();
  
  // Show splash screen while initializing
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider(create: (context) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, UserProvider>(
          create: (context) => UserProvider(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, previous) => previous ?? UserProvider(
            authService: authService,
          ),
        ),
      ],
      child: const ThemeInitializer(),
    ),
  );
}

class ThemeInitializer extends StatelessWidget {
  const ThemeInitializer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Show a simple loading screen until theme is initialized
        if (!themeProvider.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        // Once theme is initialized, show the actual app
        return const MyApp();
      },
    );
  }
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
            ),
            scaffoldBackgroundColor: Colors.grey.shade50,
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 5,
                shadowColor: Colors.blue.withAlpha(77),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark
            ).copyWith(
              surface: Colors.black,
            ),
            scaffoldBackgroundColor: Colors.grey.shade900,
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 5,
                shadowColor: Colors.blue.withAlpha(77),
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