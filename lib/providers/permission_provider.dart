import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionProvider extends ChangeNotifier {
  Map<String, dynamic> _permissions = {};

  Map<String, dynamic> get permissions => _permissions;

  /// 🔹 Load from SharedPreferences
  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('permissions');

    if (data != null) {
      _permissions = jsonDecode(data);
    }

    notifyListeners();
  }

  /// 🔹 Main checker
  bool hasPermission(String module, String submodule, String action) {
    try {
      return _permissions[module]?[submodule]?[action] == true;
    } catch (e) {
      return false;
    }
  }

  /// 🔹 Clear on logout
  void clear() {
    _permissions = {};
    notifyListeners();
  }
}
