import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'ar'; // Default to Arabic

  @override
  void initState() {
    super.initState();
    // Load saved language preference
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    // For now, default to Arabic
    // In a real app, you would load this from SharedPreferences
    setState(() {
      _selectedLanguage = 'ar';
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // In a real app, you would save this to SharedPreferences
    // and restart the app or update the locale

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language changed to English')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.purple.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Theme Settings
            Container(
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Dark Mode Toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListTile(
                        leading: Icon(
                          themeProvider.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        title: Text(
                          themeProvider.themeMode == ThemeMode.dark
                              ? 'Dark Mode'
                              : 'Light Mode',
                        ),
                        trailing: Switch(
                          value: themeProvider.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Info
            Container(
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.school),
                    title: Text('Multiplication Master'),
                    subtitle: Text('Learn • Practice • Excel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
