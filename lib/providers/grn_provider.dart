import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

class GRNProvider with ChangeNotifier {
  List<GRN> _grns = [];
  List<String> _returnReasons = [];
  List<DebitCreditNote> _debitCreditNotes = [];

  bool _isLoading = false;
  bool _isLoadMore = false;
  String? _error;

  String _filterStatus = "active";
  bool _hasMore = true;

  int _skip = 0;
  int _limit = 50;

  static const String _baseApi = 'http://192.168.29.184:8000/nextjstestapi';
  static const String _grnBase = '$_baseApi/grns';
  static const String _grnListEndpoint = '$_grnBase/';

  // static const String _returnReasonsEndpoint =
  //     '$_grnBase/getgrn/return-reasons';

  List<GRN> get grns => _grns;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  List<String> get returnReasons => _returnReasons;
  List<DebitCreditNote> get debitCreditNotes => _debitCreditNotes;
  int get skip => _skip;
  int get limit => _limit;
  bool get hasMore => _hasMore;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

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
    _skip = 0;
    _hasMore = true;
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

  // Future<String> addReturnReason(String reason) async {
  //   setLoading(true);
  //   try {
  //     final response = await _dio.post(
  //       _returnReasonsEndpoint.replaceFirst(
  //         '/getgrn/return-reasons',
  //         '/return-reasons',
  //       ),
  //       data: {'reason': reason},
  //       options: Options(headers: {'Content-Type': 'application/json'}),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       await fetchReturnReasons();
  //       return response.data['message'] ?? 'Reason added successfully';
  //     } else {
  //       throw Exception('Failed to add reason: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     setLoading(false);
  //   }
  // }

  Future<void> fetchReturnReasons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get(
        'https://yenerp.com/purchaseapi/grns/getgrn/return-reasons',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        _returnReasons = data
            .map<String>((e) => e['reason'].toString())
            .toList();
      } else {
        _returnReasons = [];
        _error = 'Failed to fetch return reasons: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching return reasons: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFilteredGRNs({
    String? status,
    String? vendorName,
    DateTime? date,
    int skip = 0,
    int limit = 50,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        _isLoading = true;
        _error = null;
        _grns = [];
        notifyListeners();
      } else {
        _isLoadMore = true;
        notifyListeners();
      }

      String endpoint = _grnListEndpoint;

      // 🔥 SWITCH API
      if (status?.toLowerCase() == "returned") {
        endpoint = '$_grnBase/returnprocess/Grnwise';
      }

      final queryParams = {
        "skip": skip,
        "limit": limit,
        if (status != null && status != "returned")
          "status": status == "active" ? null : status,
        if (vendorName != null && vendorName.isNotEmpty)
          "vendorName": vendorName,
        if (date != null) "fromDate": date.toIso8601String(),
        if (date != null) "toDate": date.toIso8601String(),
      };

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      final List<dynamic> data = response.data;

      List<GRN> newGrns = data.map((e) => GRN.fromJson(e)).toList();

      if (status == "active") {
        newGrns = newGrns.where((g) {
          final s = (g.status ?? "").toLowerCase().replaceAll(" ", "");
          return s != "fullyreturned";
        }).toList();
      }
      if (loadMore) {
        _grns.addAll(newGrns);
      } else {
        _grns = newGrns;
      }

      _hasMore = newGrns.length == limit;
    } catch (e) {
      _error = "Failed to fetch GRNs";
    } finally {
      _isLoading = false;
      _isLoadMore = false;
      notifyListeners();
    }
  }

  String _getReadableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out.";

      case DioExceptionType.connectionError:
        return "No internet connection.";

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;

        if (statusCode >= 500) {
          return "Server error.";
        } else if (statusCode == 404) {
          return "Data not found.";
        } else if (statusCode == 400) {
          return "Invalid request.";
        } else {
          return "Something went wrong.";
        }

      case DioExceptionType.cancel:
        return "Request cancelled.";

      default:
        return "Unexpected error.";
    }
  }

  Future<bool> updateGRN(GRN grn, String newStatus) async {
    setLoading(true);
    setError(null);

    try {
      final currentDate = ServerTimeService.now;

      final formattedDate = DateFormat(
        'yyyy-MM-ddTHH:mm:ss',
      ).format(currentDate);

      final response = await _dio.patch(
        '$_grnBase/${grn.grnId}',
        data: {"status": newStatus, "lastUpdatedDate": formattedDate},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

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

      final double grnAmount = grn.grnAmount ?? 0.0;
      final double finalApRoundOff = roundOffAdjustment;
      final response = await _dio.patch(
        '$_grnBase/convert-to-ap/ap-to-outgoing/$grnId',
        queryParameters: {'apRoundOff': finalApRoundOff.toStringAsFixed(2)},
        data: itemsJson,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFilteredGRNs(status: _filterStatus, skip: 0, limit: _limit);
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
      return null;
    }
  }

  Future<List<GRN>> fetchGrnsWithItemStatus(String status) async {
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
      return [];
    } finally {
      setLoading(false);
    }
  }

  Future<List<String>> fetchRandomNumbers() async {
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
      return [];
    } finally {
      setLoading(false);
    }
  }

  Future<dynamic> returnGrn(String grnId, ReturnGRNRequest data) async {
    try {
      if (grnId.isEmpty) throw Exception('GRN ID cannot be empty');
      if (data.returnedBy.isEmpty) {
        throw Exception('Returned by field cannot be empty');
      }

      final requestBody = {
        "scenario": data.scenario?.toLowerCase() ?? "",
        "returnedDate": (data.returnedDate ?? ServerTimeService.now)
            .toIso8601String(),
        "returnedBy": data.returnedBy,
        "comments": data.comments ?? "",
        "items": data.items
            ?.where(
              (i) =>
                  i.itemId != null &&
                  i.itemId!.isNotEmpty &&
                  i.itemId!.length == 24,
            )
            .map(
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

      // 🔍 DEBUG (optional but useful)
      print("RETURN PAYLOAD: $requestBody");

      final response = await _dio.patch(
        '$_grnBase/$grnId/return',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final res = response.data;
        await fetchFilteredGRNs(status: _filterStatus, skip: 0, limit: _limit);
        notifyListeners();
        return res;
      } else {
        throw Exception('Failed: ${response.statusCode} -> ${response.data}');
      }
    } catch (e) {
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
