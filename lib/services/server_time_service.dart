import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ServerTimeService {
  static DateTime? _cachedServerTime;

  static final Dio _dio = Dio();

  static Future<void> initialize() async {
    try {
      final response =
          await _dio.get("https://yenerp.com/liveapi/datetime");

      if (response.statusCode == 200) {
        final date = response.data["current_date"];
        final time = response.data["current_time"];

        _cachedServerTime =
            DateFormat("dd-MM-yyyy hh:mm a").parse("$date $time");
      }
    } catch (e) {
      throw Exception("Unable to fetch server time");
    }
  }

  static DateTime get now {
    if (_cachedServerTime == null) {
      throw Exception("ServerTimeService not initialized");
    }
    return _cachedServerTime!;
  }

  static Future<void> refresh() async {
    await initialize();
  }
}
