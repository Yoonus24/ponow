// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/grnitem.dart';

class GRNProvider with ChangeNotifier {
  List<GRN> _grns = [];
  List<String> _returnReasons = [];
  List<DebitCreditNote> _debitCreditNotes = [];

  bool _isLoading = false;
  String? _error;

  String _filterStatus = "";

  int _skip = 0;
  int _limit = 50;

  static const String _baseApi = 'http://192.168.29.252:8000/nextjstestapi';
  static const String _grnBase = '$_baseApi/grns';
  static const String _grnListEndpoint = '$_grnBase/getAll';

  static const String _returnReasonsEndpoint =
      '$_grnBase/getgrn/return-reasons';

  List<GRN> get grns => _grns;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  List<String> get returnReasons => _returnReasons;
  List<DebitCreditNote> get debitCreditNotes => _debitCreditNotes;
  int get skip => _skip;
  int get limit => _limit;

  GRNProvider() {
    fetchReturnReasons();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setPagination({int? skip, int? limit}) {
    if (skip != null) _skip = skip;
    if (limit != null) _limit = limit;
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    print('🔎 Filter Status (raw): $_filterStatus');

    if (status == 'returned') {
      fetchReturnedGRNs();
    } else {
      fetchFilteredGRNs();
    }
  }

  String normalizeStatus(String raw) {
    raw = raw.toLowerCase();

    if (raw == "active") return "Active";

    if (raw == "returned") return "FullyReturned";
    if (raw.contains("partial")) return "PartiallyReturned";

    if (raw.contains("full")) return "FullyReturned";

    if (raw.contains("ap")) return "APInvoiceConverted";

    return raw;
  }

  Future<String> addReturnReason(String reason) async {
    print('[API] addReturnReason: $reason');
    setLoading(true);
    try {
      final dio = Dio();
      final response = await dio.post(
        _returnReasonsEndpoint.replaceFirst(
          '/getgrn/return-reasons',
          '/return-reasons',
        ),
        data: {'reason': reason},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchReturnReasons();
        return response.data['message'] ?? 'Reason added successfully';
      } else {
        throw Exception('Failed to add reason: ${response.statusCode}');
      }
    } catch (e) {
      print('[API] addReturnReason error: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchReturnReasons() async {
    print('[API] fetchReturnReasons');
    setLoading(true);
    _error = null;
    try {
      final dio = Dio();
      final response = await dio.get(
        _returnReasonsEndpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _returnReasons = data
            .map<String>((e) => e['reason'].toString())
            .toList();
        print('[API] fetched return reasons: $_returnReasons');
      } else {
        _returnReasons = [];
        _error = 'Failed to fetch return reasons: ${response.statusCode}';
        print('❌ fetchReturnReasons status: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error fetching return reasons: $e';
      print('❌ fetchReturnReasons exception: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchFilteredGRNs({
    String? status,
    String? vendorName,
    DateTime? date,
    int? skip,
    int? limit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (status != null && status.toLowerCase() == "returned") {
        print("🔄 Fetching BOTH partial & full returned GRNs");
        await fetchFilteredGRNs(status: "PartiallyReturned");
        List<GRN> partials = List.from(_grns);
        await fetchFilteredGRNs(status: "FullyReturned");
        List<GRN> fulls = List.from(_grns);
        _grns = [...partials, ...fulls];
        notifyListeners();
        return;
      }
      final effectiveSkip = skip ?? _skip;
      final effectiveLimit = limit ?? _limit;
      final queryParams = {
        "skip": "$effectiveSkip",
        "limit": "$effectiveLimit",
      };

      if (status != null && status.isNotEmpty) queryParams["status"] = status;

      if (vendorName != null && vendorName.trim().isNotEmpty)
        queryParams["vendorName"] = vendorName.trim();

      if (date != null)
        queryParams["date"] = DateFormat("yyyy-MM-dd").format(date);

      final uri = Uri.parse(
        _grnListEndpoint,
      ).replace(queryParameters: queryParams);
      print("🌐 GET $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        _grns = (jsonDecode(response.body) as List)
            .map((e) => GRN.fromJson(e))
            .toList();
      } else {
        _grns = [];
      }
    } catch (e) {
      _error = "Error fetching GRNs: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<GRN>> _fetchByStatus(String status) async {
    final uri = Uri.parse(_grnListEndpoint).replace(
      queryParameters: {"skip": "$_skip", "limit": "$_limit", "status": status},
    );

    print("🌐 RAW FETCH $uri");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GRN.fromJson(e)).toList();
    }

    return [];
  }

  Future<bool> updateGRN(GRN grn, String newStatus) async {
    print('--- updateGRN called for ${grn.grnId} ---');
    setLoading(true);
    setError(null);

    try {
      final currentDate = DateTime.now();
      final formattedDate = DateFormat(
        'yyyy-MM-ddTHH:mm:ss',
      ).format(currentDate);

      grn.status = newStatus;
      grn.lastUpdatedDate = formattedDate;

      final uri = Uri.parse('$_grnBase/${grn.grnId}');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(grn.toJson());

      final response = await http.patch(uri, headers: headers, body: body);
      print('PATCH status: ${response.statusCode}');
      print('PATCH body: ${response.body}');

      if (response.statusCode == 200) {
        final updatedGrn = GRN.fromJson(jsonDecode(response.body));
        final index = _grns.indexWhere((item) => item.grnId == grn.grnId);
        if (index != -1) {
          _grns[index] = updatedGrn;
          notifyListeners();
        }
        return true;
      } else {
        throw Exception('Failed to update GRN: ${response.body}');
      }
    } catch (error) {
      setError(error.toString());
      print('❌ updateGRN exception: $error');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> convertGrnToApAndOutgoing({
    required String grnId,
    required double discountPrice,
    required double roundOffAdjustment,
    required List<ItemDetail> itemUpdates,
  }) async {
    print('--- convertGrnToApAndOutgoing called for $grnId ---');
    setLoading(true);
    setError(null);

    try {
      // 🔍 Debug: log incoming items
      for (var item in itemUpdates) {
        print(
          '🧾 ItemUpdate -> id: ${item.itemId}, '
          'bef: ${item.befTaxDiscount}, af: ${item.afTaxDiscount}, '
          'expiry: ${item.expiryDate}',
        );
      }

      // ✅ Filter only valid items with itemId
      final List<Map<String, dynamic>> itemUpdatesJson = itemUpdates
          .where((item) => item.itemId != null && item.itemId!.isNotEmpty)
          .map((item) {
            return {
              'itemId': item.itemId,
              'befTaxDiscount': item.befTaxDiscount ?? 0.0,
              'afTaxDiscount': item.afTaxDiscount ?? 0.0,
              'expiryDate': item.expiryDate,
            };
          })
          .toList();

      if (itemUpdatesJson.isEmpty) {
        throw Exception('No valid items with itemId to convert');
      }

      // ✅ Build URL with round-off
      final uri = Uri.parse('$_grnBase/convert-to-ap/ap-to-outgoing/$grnId')
          .replace(
            queryParameters: {
              'apRoundOff': roundOffAdjustment.toStringAsFixed(2),
            },
          );

      print('🚀 CONVERT URL: $uri');

      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(itemUpdatesJson);

      print('📤 PATCH $uri');
      print('Request body: $body');

      final response = await http.patch(uri, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        await fetchFilteredGRNs();

        return {
          'success': true,
          'message': result['message'] ?? 'Conversion successful',
          'data': result,
        };
      } else {
        throw Exception(
          'Failed to convert GRN: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      setError(error.toString());
      print('❌ convertGrnToApAndOutgoing exception: $error');

      return {'success': false, 'error': error.toString()};
    } finally {
      setLoading(false);
    }
  }

  // Add this method to GRNProvider class
  Future<Map<String, dynamic>?> fetchPODetails(String poId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseApi/purchaseorders/$poId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching PO details: $e');
      return null;
    }
  }

  // Add this method to convert from Approved PO to GRN with round-off
  // Update the convertFromApprovedPOToGRN method in GRNProvider
  Future<Map<String, dynamic>> convertFromApprovedPOToGRN({
    required String poId,
    required String invoiceNo,
    required DateTime invoiceDate,
    required List<Map<String, dynamic>> items,
    required double discount,
    required double roundOffAdjustment,
  }) async {
    print('=== Starting convertFromApprovedPOToGRN ===');
    print('PO ID: $poId');
    print('Invoice No: $invoiceNo');
    print('Round Off Adjustment: $roundOffAdjustment');
    print('Discount: $discount');

    setLoading(true);
    setError(null);

    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'poId': poId,
        'invoiceNo': invoiceNo,
        'invoiceDate': DateFormat('yyyy-MM-dd').format(invoiceDate),
        'discountPrice': discount,
        'roundOffAdjustment': roundOffAdjustment,
        'freights': 0.0, // 👈 ADD THIS LINE
        'items': items,
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      // Try different endpoints - Use the existing convert-to-ap endpoint
      final response = await http.post(
        Uri.parse('$_grnBase/convert-to-ap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Refresh GRN list
        await fetchFilteredGRNs();

        return {
          'success': true,
          'grnId': responseData['grnId'],
          'message': 'GRN created successfully',
          'roundOffAdjustment':
              responseData['roundOffAdjustment'] ?? roundOffAdjustment,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error in convertFromApprovedPOToGRN: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  Future<List<GRN>> fetchGrnsWithItemStatus(String status) async {
    print('Starting fetchGrnsWithItemStatus for status: $status');
    setLoading(true);
    setError(null);

    try {
      final response = await http.get(
        Uri.parse('$_grnBase/items/status/$status'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final grnsList = data.map((item) => GRN.fromJson(item)).toList();
        _grns = grnsList;
        notifyListeners();
        return grnsList;
      } else {
        throw Exception(
          'Failed to fetch GRNs with status: ${response.statusCode}',
        );
      }
    } catch (error) {
      setError('Failed to fetch GRNs with status: $error');
      print('❌ fetchGrnsWithItemStatus exception: $error');
      return [];
    } finally {
      setLoading(false);
    }
  }

  Future<List<String>> fetchRandomNumbers() async {
    print('Starting fetchRandomNumbers...');
    setLoading(true);
    setError(null);

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseApi/purchaseorders/getByRandomId'.replaceFirst(
            '/nextjstestapi',
            '/nextjstestapi',
          ),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception(
          'Failed to fetch random numbers. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      setError('Failed to fetch random numbers: $error');
      print('❌ fetchRandomNumbers exception: $error');
      return [];
    } finally {
      setLoading(false);
    }
  }

  Future<dynamic> returnGrn(String grnId, ReturnGRNRequest data) async {
    try {
      if (grnId.isEmpty) throw Exception('GRN ID cannot be empty');
      if (data.returnedBy.isEmpty)
        throw Exception('Returned by field cannot be empty');

      final url = Uri.parse('$_grnBase/$grnId/return');

      final requestBody = {
        "scenario": data.scenario?.toLowerCase() ?? "",
        "returnedDate": (data.returnedDate ?? DateTime.now()).toIso8601String(),
        "returnedBy": data.returnedBy,
        "comments": data.comments ?? "",
        "items": data.items
            ?.map(
              (i) => {
                "itemId": i.itemId,
                "nos": i.nos ?? 1.0,
                "eachQuantity": i.eachQuantity ?? 1.0,
                "returnReason": i.returnReason,
                "returnedQuantity": i.returnedQuantity,
              },
            )
            .toList(),
      };

      print('📤 returnGrn request: ${jsonEncode(requestBody)}');

      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('📥 returnGrn response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        await fetchFilteredGRNs();
        notifyListeners();
        return res;
      } else {
        throw Exception('Failed: ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      print('❌ returnGrn exception: $e');
      throw Exception('Failed to process GRN return: $e');
    }
  }

  Future<void> fetchReturnedGRNs({int skip = 0, int limit = 50}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '$_baseApi/grns/returnprocess/Grnwise?skip=$skip&limit=$limit',
      );

      print('🌐 GET RETURNED GRNS $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        _grns = (jsonDecode(response.body) as List)
            .map((e) => GRN.fromJson(e))
            .toList();
      } else {
        _grns = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDebitCreditNotesByGrnId(
    String grnId, {
    int skip = 0,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        '$_baseApi/returnprocess/DebitCreditNote/$grnId?skip=$skip&limit=$limit',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _debitCreditNotes = data
            .map((json) => DebitCreditNote.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        _debitCreditNotes = [];
        _error = 'No debit/credit notes found for GRN ID: $grnId';
      } else if (response.statusCode == 400) {
        _error = 'Invalid GRN ID format';
      } else {
        _error = 'Failed to fetch debit/credit notes: ${response.reasonPhrase}';
      }
    } catch (e) {
      _error = 'Error fetching debit/credit notes: $e';
      print('❌ fetchDebitCreditNotesByGrnId exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _grns = [];
    _returnReasons = [];
    _debitCreditNotes = [];
    _error = null;
    _isLoading = false;
    super.dispose();
  }
}
