import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberedCredentials {
  const RememberedCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class RememberMeStorage {
  static const String _nameKey = 'twfood_remember_name';
  static const String _emailKey = 'twfood_remember_email';
  static const String _rememberKey = 'twfood_remember_enabled';
  static const String _passwordKey = 'twfood_remember_password';

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static Future<void> save({
    required String name,
    required String email,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_nameKey, name);
    await preferences.setString(_emailKey, email);
    await preferences.setBool(_rememberKey, true);

    await _secureStorage.write(
      key: _passwordKey,
      value: password,
    );
  }

  static Future<RememberedCredentials?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_rememberKey) ?? false;

    if (!enabled) return null;

    final email = preferences.getString(_emailKey);
    final password = await _secureStorage.read(key: _passwordKey);

    if (email == null || email.isEmpty || password == null) {
      await clear();
      return null;
    }

    return RememberedCredentials(
      email: email,
      password: password,
    );
  }

  static Future<String?> getSavedName() async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(_rememberKey) ?? false)) return null;
    return preferences.getString(_nameKey);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_nameKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_rememberKey);
    await _secureStorage.delete(key: _passwordKey);
  }
}
