import 'package:flutter/material.dart';

/// Drives Light/Dark/System theme switching app-wide. Kept deliberately
/// simple (in-memory) — the toggle lives in the Settings screen and in a
/// quick-access AppBar action on Home.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  void setMode(ThemeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  void toggle(BuildContext context) {
    setMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}
