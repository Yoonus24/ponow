import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool _showBackOnline = false;

  VoidCallback? onReconnect;

  bool get isConnected => _isConnected;
  bool get showBackOnline => _showBackOnline;
  DateTime? _lastReconnect;
  bool _disposed = false;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();

      _updateStatus(results);

      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (e, stackTrace) {
      debugPrint("Connectivity init error: $e");

      debugPrint(stackTrace.toString());

      _isConnected = true;
    }
  }

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

      Future.delayed(const Duration(seconds: 3), () {
        if (_disposed) return;

        _showBackOnline = false;

        notifyListeners();
      });
    }

    _isConnected = connected;

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    _subscription?.cancel();

    super.dispose();
  }
}
