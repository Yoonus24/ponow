import 'dart:async';
import 'package:purchaseorders2/services/auth_service.dart';

class SessionService {
  static Timer? _timer;

  static void start() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      try {
        await AuthService.ping();
      } catch (e) {
        throw Exception("SESSION_PING_FAILED");
      }
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
