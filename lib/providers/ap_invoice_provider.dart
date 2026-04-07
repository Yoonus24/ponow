// ignore_for_file: prefer_final_fields, use_build_context_synchronously, avoid_print, use_rethrow_when_possible

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/pdfs/apinvoice_pdf.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/services/dio_client.dart'; // Import DioClient

class APInvoiceProvider extends ChangeNotifier {
  List<ApInvoice> _apInvoices = [];
  final List<Outgoing> _outgoings = [];
  List<GRN> _grns = [];
  bool _loading = false;
  String? _error;
  String _filterStatus = 'Pending';
  bool _isFetching = false;
  List<ApInvoice> get apInvoices => _apInvoices;
  List<Outgoing> get outgoings => _outgoings;
  List<GRN> get grns => _grns;
  bool get loading => _loading;
  String get filterStatus => _filterStatus;
  bool _isInitialLoad = true;
  bool get isInitialLoad => _isInitialLoad;
  bool hasMore = true;
  bool isLoadingMore = false;
  Map<String, bool> _pdfLoadingMap = {};

  set filterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  String? get error => _error;

  APInvoiceProvider() {
    _ensureDioInitialized();
  }

  // Ensure DioClient is initialized
  Future<void> _ensureDioInitialized() async {
    await DioClient.init();
  }

  bool isPdfLoading(String invoiceId) {
    return _pdfLoadingMap[invoiceId] ?? false;
  }

  Future<void> fetchAPInvoices({
    String? status,
    String? vendorName,
    DateTime? fromDate,
    DateTime? toDate,
    int skip = 0,
    int limit = 50,
  }) async {
    if (_isFetching) return;

    _isFetching = true;

    // Reset pagination when new filter applied
    if (skip == 0) {
      hasMore = true;
      _setLoading(true);
    }

    _setError(null);

    try {
      String? formattedFromDate;
      String? formattedToDate;

      if (fromDate != null) {
        formattedFromDate =
            "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      }

      if (toDate != null) {
        formattedToDate =
            "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";
      }

      final queryParams = {
        'skip': skip,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (vendorName != null && vendorName.isNotEmpty)
          'vendorName': vendorName,
        if (formattedFromDate != null) 'fromDate': formattedFromDate,
        if (formattedToDate != null) 'toDate': formattedToDate,
      };

      // Use DioClient.dio instead of creating new Dio instance
      final response = await DioClient.dio.get(
        '/apinvoices/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        _isInitialLoad = false;

        List<dynamic> data;

        // Handle both List and Map responses
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'];
        } else {
          data = [];
        }

        print("AP RAW RESPONSE => $data");

        final newInvoices = data.map((e) => ApInvoice.fromJson(e)).toList();

        if (skip == 0) {
          _apInvoices = newInvoices;
        } else {
          _apInvoices.addAll(newInvoices);
        }

        hasMore = newInvoices.length == limit;
      }
    } catch (e) {
      print("AP INVOICE ERROR => $e");

      if (e is DioException) {
        _setError(_getReadableError(e));
      } else {
        _setError("Something went wrong. Please try again.");
      }
    } finally {
      _loading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> generatePdf(ApInvoice apinvoice, BuildContext context) async {
    final id = apinvoice.invoiceId!;

    _pdfLoadingMap[id] = true;
    notifyListeners();

    try {
      final pdfService = APInvoicePDF();

      final pdfFile = await pdfService.generateAPInvoicePdf(id);

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF failed: $e')));
    } finally {
      _pdfLoadingMap[id] = false;
      notifyListeners();
    }
  }

  Future<void> convertToGrnFromApReturned(
    String invoiceId,
    BuildContext context,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      // Use DioClient.dio instead of creating new Dio instance
      final response = await DioClient.dio.patch(
        '/apinvoices/convert-to-grn-from-returned/$invoiceId',
      );

      if (response.statusCode == 200) {
        _apInvoices.removeWhere((inv) => inv.invoiceId == invoiceId);
        notifyListeners();

        final grnProvider = Provider.of<GRNProvider>(context, listen: false);
        final outgoingProvider = Provider.of<OutgoingPaymentProvider>(
          context,
          listen: false,
        );

        await Future.wait([
          fetchAPInvoices(status: "Outgoing Posted", skip: 0, limit: 50),
          grnProvider.fetchFilteredGRNs(),
          outgoingProvider.fetchFilteredOutgoings(),
        ]);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AP returned to GRN successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Return failed.");
      }
    } on DioException catch (e) {
      final message = _getReadableError(e);
      _setError(message);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.grey),
        );
      }
    } catch (e) {
      const message = "Something went wrong.";
      _setError(message);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(message)));
      }
    } finally {
      _setLoading(false);
    }
  }

  String _getReadableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return "No internet connection.";
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return "Request timed out.";
      case DioExceptionType.badResponse:
        return "Server error.";
      default:
        return "Unexpected error.";
    }
  }

  void _setLoading(bool isLoading) {
    _loading = isLoading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void postOutgoingAndUpdateStatus(String s) {}
}

// Remove the RetryInterceptor class as it's no longer needed
// (unless used elsewhere in your codebase)
