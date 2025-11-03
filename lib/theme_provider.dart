import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme
  bool _isInitialized = false;

  ThemeProvider() {
    _init();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final themeIndex = _prefs.getInt(_themeKey);
      
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        // If no theme is saved, use light theme as default
        _themeMode = ThemeMode.light;
        await _saveTheme(_themeMode);
      }
    } catch (e) {
      // In case of any error, fall back to light theme
      _themeMode = ThemeMode.light;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      await _prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Handle error if saving fails
      debugPrint('Error saving theme: $e');
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(_themeMode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveTheme(mode);
      notifyListeners();
    }
  }
}
