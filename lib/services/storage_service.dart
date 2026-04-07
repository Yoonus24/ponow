// import 'package:shared_preferences/shared_preferences.dart';

// class StorageService {
//   static Future<void> saveSession({
//     required String token,
//     required String browserId,
//     required String tabId,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();

//     await prefs.setString('token', token);
//     await prefs.setString('browser_session_id', browserId);
//     await prefs.setString('tab_id', tabId);
//   }

//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }

//   static Future<String?> getBrowserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('browser_session_id');
//   }

//   static Future<String?> getTabId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('tab_id');
//   }

//   static Future<void> clear() async {
//     final prefs = await SharedPreferences.getInstance();

//     await prefs.remove('token');
//     await prefs.remove('tab_id');
//     await prefs.remove('username');

//   }
// }