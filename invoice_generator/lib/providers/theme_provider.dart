import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _settingsBoxName = 'settings_box';
const String _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final box = await Hive.openBox(_settingsBoxName);
    final savedValue = box.get(_themeModeKey) as String?;

    if (savedValue != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedValue,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = await Hive.openBox(_settingsBoxName);
    await box.put(_themeModeKey, mode.name);
  }

  Future<void> toggleLightDark() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);