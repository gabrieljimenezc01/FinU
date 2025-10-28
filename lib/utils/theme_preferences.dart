import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _key = 'isDarkMode';

  // Guarda la preferencia del usuario
  Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDarkMode);
  }

  // Obtiene la preferencia guardada, por defecto false (tema claro)
  Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}
