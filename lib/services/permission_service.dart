import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static Map<String, dynamic> _permissions = {};

  static Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("permissions");

    if (data != null) {
      _permissions = jsonDecode(data);
    }
  }

  static bool hasPermission(String module, String action) {
    try {
      return _permissions['yenerp']?[module]?[action] == true;
    } catch (e) {
      return false;
    }
  }
}
