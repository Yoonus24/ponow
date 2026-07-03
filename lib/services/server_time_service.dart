import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/services/dio_client.dart';

class ServerTimeService {
  static Duration? _serverOffset;
  static final Dio _dio = DioClient.dio;

  static Future<void> initialize() async {
    try {
      final response = await _dio.get("https://yenerp.com/liveapi/datetime");

      if (response.statusCode == 200) {
        final date = response.data["current_date"];
        final time = response.data["current_time"];

        debugPrint("API RESPONSE => ${response.data}");

        final serverTime = DateFormat(
          "dd-MM-yyyy hh:mm a",
        ).parse("$date $time");

        final deviceTime = DateTime.now();

        // debugPrint("SERVER TIME => $serverTime");

        // debugPrint("DEVICE TIME => $deviceTime");

        _serverOffset = serverTime.difference(deviceTime);

        // debugPrint("OFFSET => $_serverOffset");
      }
    } catch (e) {
      debugPrint("ServerTimeService Error => $e");

      throw Exception("Unable to fetch server time");
    }
  }

  static DateTime get now {
    if (_serverOffset == null) {
      throw Exception("ServerTimeService not initialized");
    }

    final currentServerTime = DateTime.now().add(_serverOffset!);

    // debugPrint("CURRENT SERVER TIME => $currentServerTime");

    return currentServerTime;
  }

  static Future<void> refresh() async {
    await initialize();
  }
}