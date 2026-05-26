import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/storage/secure_storage_service.dart';

class PermissionProvider extends ChangeNotifier {
  Map<String, dynamic> _permissions = {};

  Map<String, dynamic> get permissions => _permissions;

  Future<void> loadPermissions() async {
    final data = await SecureStorageService.getPermissions();

    if (data != null && data.isNotEmpty) {
      try {
        _permissions = jsonDecode(data);
      } catch (e, stackTrace) {
        final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

        debugPrint("Permission parsing error: ${exception.message}");

        _permissions = {};
      }
    } else {
      _permissions = {};
    }

    notifyListeners();
  }

  bool hasPermission(String module, String submodule, String action) {
    if (_permissions.isEmpty) return false;

    if (module == 'yenerp') {
      return _permissions[module]?[submodule]?[action] == true;
    }

    return _permissions['yenerp']?[module]?[action] == true;
  }

  bool hasEditAction(String module, String action) {
    if (_permissions.isEmpty) return false;

    final moduleData = _permissions['yenerp']?[module];

    final hasEdit = moduleData?['edit'] == true;

    final hasAction = moduleData?['edit_actions']?[action] == true;

    return hasEdit && hasAction;
  }

  Future<void> clear() async {
    _permissions = {};

    await SecureStorageService.clearAll();

    notifyListeners();
  }
}
