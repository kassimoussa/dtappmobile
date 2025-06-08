// lib/services/config_service.dart
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectionMode {
  api,
  ussd,
}

class ConfigService {
  static const String _modeKey = 'connection_mode';
  
  Future<ConnectionMode> getConnectionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_modeKey) ?? 'api';
    return ConnectionMode.values.firstWhere(
      (mode) => mode.toString() == 'ConnectionMode.$modeString',
      orElse: () => ConnectionMode.api,
    );
  }
  
  Future<void> setConnectionMode(ConnectionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.toString().split('.').last);
  }
}