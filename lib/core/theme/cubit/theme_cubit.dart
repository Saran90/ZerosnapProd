import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final saved = prefs.getString(AppConstants.themeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setLight() => _save(ThemeMode.light);
  void setDark() => _save(ThemeMode.dark);
  void setSystem() => _save(ThemeMode.system);

  void toggle() {
    if (state == ThemeMode.light) {
      _save(ThemeMode.dark);
    } else {
      _save(ThemeMode.light);
    }
  }

  void _save(ThemeMode mode) {
    emit(mode);
    final key = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    _prefs.setString(AppConstants.themeKey, key);
  }
}
