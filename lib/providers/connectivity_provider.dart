import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;
  bool _showBackOnline = false;
  VoidCallback? onReconnect;
  bool get isConnected => _isConnected;
  bool get showBackOnline => _showBackOnline;
  
  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  DateTime? _lastReconnect;

  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);

    if (!_isConnected && connected) {
      final now = DateTime.now();

      if (_lastReconnect == null ||
          now.difference(_lastReconnect!) > const Duration(seconds: 5)) {
        onReconnect?.call();
        _lastReconnect = now;
      }

      _showBackOnline = true;
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        _showBackOnline = false;
        notifyListeners();
      });
    }

    _isConnected = connected;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
