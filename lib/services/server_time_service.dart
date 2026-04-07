import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ServerTimeService {
  static Duration? _serverOffset;
  static final Dio _dio = Dio();

  static Future<void> initialize() async {
    try {
      final response = await _dio.get("https://yenerp.com/liveapi/datetime");

      if (response.statusCode == 200) {
        final date = response.data["current_date"];
        final time = response.data["current_time"];

        final serverTime = DateFormat(
          "dd-MM-yyyy hh:mm a",
        ).parse("$date $time");

        final deviceTime = DateTime.now();

        _serverOffset = serverTime.difference(deviceTime);
      }
    } catch (e) {
      throw Exception("Unable to fetch server time");
    }
  }
  

  static DateTime get now {
    if (_serverOffset == null) {
      throw Exception("ServerTimeService not initialized");
    }
    return DateTime.now().add(_serverOffset!);
  }

  static Future<void> refresh() async {
    await initialize();
  }
}
