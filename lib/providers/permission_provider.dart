import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionProvider extends ChangeNotifier {
  Map<String, dynamic> _permissions = {};

  Map<String, dynamic> get permissions => _permissions;

  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('permissions');

    if (data != null && data.isNotEmpty) {
      try {
        _permissions = jsonDecode(data);
      } catch (e) {
        _permissions = {}; // Prevent crash if corrupted
      }
    } else {
      _permissions = {}; // Reset if null
    }

    notifyListeners();
  }

  bool hasPermission(String module, String submodule, String action) {
    try {
      if (module == 'yenerp') {
        return _permissions[module]?[submodule]?[action] == true;
      }
      return _permissions['yenerp']?[module]?[action] == true;
    } catch (e) {
      return false;
    }
  }

  bool hasEditAction(String module, String action) {
    try {
      final moduleData = _permissions['yenerp']?[module];

      final hasEdit = moduleData?['edit'] == true;
      final hasAction = moduleData?['edit_actions']?[action] == true;

      return hasEdit && hasAction;
    } catch (e) {
      return false;
    }
  }

  Future<void> clear() async {
    _permissions = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('permissions'); // Clear storage also

    notifyListeners();
  }
}
