// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  final Dio _dio = Dio();

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
      final response = await _dio.post(
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
      final response = await _dio.get(
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

      final response = await _dio.get(
        _grnListEndpoint,
        queryParameters: queryParams,
      );

      print("🌐 GET ${response.realUri}");

      if (response.statusCode == 200) {
        _grns = (response.data as List).map((e) => GRN.fromJson(e)).toList();
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
    try {
      final response = await _dio.get(
        _grnListEndpoint,
        queryParameters: {
          "skip": "$_skip",
          "limit": "$_limit",
          "status": status,
        },
      );

      print("🌐 RAW FETCH ${response.realUri}");

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) => GRN.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
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

      final response = await _dio.patch(
        '$_grnBase/${grn.grnId}',
        data: jsonEncode(grn.toJson()),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('PATCH status: ${response.statusCode}');
      print('PATCH body: ${response.data}');

      if (response.statusCode == 200) {
        final updatedGrn = GRN.fromJson(response.data);
        final index = _grns.indexWhere((item) => item.grnId == grn.grnId);
        if (index != -1) {
          _grns[index] = updatedGrn;
          notifyListeners();
        }
        return true;
      } else {
        throw Exception('Failed to update GRN: ${response.data}');
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
      final itemsJson = itemUpdates
          .where((e) => e.itemId != null && e.itemId!.isNotEmpty)
          .map(
            (e) => {
              'itemId': e.itemId,
              'befTaxDiscount': e.befTaxDiscount ?? 0.0,
              'afTaxDiscount': e.afTaxDiscount ?? 0.0,
              'expiryDate': e.expiryDate,
            },
          )
          .toList();

      if (itemsJson.isEmpty) {
        throw Exception('No valid items found');
      }

      final grn = _grns.firstWhere(
        (g) => g.grnId == grnId,
        orElse: () => throw Exception('GRN not found'),
      );

      final double grnAmount = grn.grnAmount ?? grn.totalReceivedAmount ?? 0.0;
      final double finalApRoundOff = roundOffAdjustment;

      print('🧮 ROUND OFF FLOW');
      print('GRN Amount        : $grnAmount');
      print('Manual Round Off  : $finalApRoundOff');
      print('➡️ AP Final Amount: ${grnAmount + finalApRoundOff}');

      final response = await _dio.patch(
        '$_grnBase/convert-to-ap/ap-to-outgoing/$grnId',
        queryParameters: {'apRoundOff': finalApRoundOff.toStringAsFixed(2)},
        data: jsonEncode(itemsJson),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('🚀 CONVERT URL: ${response.realUri}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFilteredGRNs();
        return {'success': true};
      } else {
        throw Exception(response.data);
      }
    } catch (e) {
      setError(e.toString());
      return {'success': false, 'error': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> fetchPODetails(String poId) async {
    try {
      final response = await _dio.get('$_baseApi/purchaseorders/$poId');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching PO details: $e');
      return null;
    }
  }

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

    setLoading(true);
    setError(null);

    try {
      final double itemFinalTotal = items.fold<double>(
        0.0,
        (sum, item) => sum + ((item['finalPrice'] ?? 0.0) as num).toDouble(),
      );

      final double roundedTotal = itemFinalTotal.roundToDouble();
      final double calculatedRoundOff = double.parse(
        (roundedTotal - itemFinalTotal).toStringAsFixed(2),
      );

      print('🧮 Item Total       : $itemFinalTotal');
      print('🧮 Rounded Total    : $roundedTotal');
      print('🧮 Round-Off Stored : $calculatedRoundOff');

      final Map<String, dynamic> requestBody = {
        'poId': poId,
        'invoiceNo': invoiceNo,
        'invoiceDate': DateFormat('yyyy-MM-dd').format(invoiceDate),
        'discountPrice': discount,
        'roundOffAdjustment': calculatedRoundOff,
        'freights': 0.0,
        'items': items,
      };

      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _dio.post(
        '$_grnBase/convert-to-ap',
        data: jsonEncode(requestBody),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        await fetchFilteredGRNs();

        return {
          'success': true,
          'grnId': responseData['grnId'],
          'message': 'GRN created successfully',
          'roundOffAdjustment': calculatedRoundOff,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode} - ${response.data}',
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
      final response = await _dio.get('$_grnBase/items/status/$status');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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
      final response = await _dio.get('$_baseApi/purchaseorders/getByRandomId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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

      final response = await _dio.patch(
        '$_grnBase/$grnId/return',
        data: jsonEncode(requestBody),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 returnGrn response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final res = response.data;
        await fetchFilteredGRNs();
        notifyListeners();
        return res;
      } else {
        throw Exception('Failed: ${response.statusCode} -> ${response.data}');
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
      final response = await _dio.get(
        '$_baseApi/grns/returnprocess/Grnwise',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      print('🌐 GET RETURNED GRNS ${response.realUri}');

      if (response.statusCode == 200) {
        _grns = (response.data as List).map((e) => GRN.fromJson(e)).toList();
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
      final response = await _dio.get(
        '$_baseApi/returnprocess/DebitCreditNote/$grnId',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _debitCreditNotes = data
            .map((json) => DebitCreditNote.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        _debitCreditNotes = [];
        _error = 'No debit/credit notes found for GRN ID: $grnId';
      } else if (response.statusCode == 400) {
        _error = 'Invalid GRN ID format';
      } else {
        _error =
            'Failed to fetch debit/credit notes: ${response.statusMessage}';
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
