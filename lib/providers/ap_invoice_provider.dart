import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';
import 'package:purchaseorders2/models/ap/ap.dart';
import 'package:purchaseorders2/models/outgoing/outgoing.dart';
import 'package:purchaseorders2/models/grn/grn.dart';
import 'package:purchaseorders2/pdfs/apinvoice_pdf.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/services/dio_client.dart';

class APInvoiceProvider extends ChangeNotifier {
  List<ApInvoice> _apInvoices = [];
  final List<Outgoing> _outgoings = [];
  final List<GRN> _grns = [];
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
  final Map<String, bool> _pdfLoadingMap = {};

  set filterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  String? get error => _error;

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

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
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

        debugPrint("AP RAW RESPONSE => $data");

        final newInvoices = data.map((e) => ApInvoice.fromJson(e)).toList();

        if (skip == 0) {
          _apInvoices = newInvoices;
        } else {
          _apInvoices.addAll(newInvoices);
        }

        hasMore = newInvoices.length == limit;
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("AP INVOICE ERROR => ${exception.message}");

      _setError(exception.message);
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
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("PDF failed: ${exception.message}");

      if (context.mounted) {
        AppSnackbar.showError(context, exception);
      }
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
      final response = await DioClient.dio.patch(
        '/apinvoices/convert-to-grn-from-returned/$invoiceId',
      );

      if (response.statusCode == 200) {
        final grnProvider = Provider.of<GRNProvider>(context, listen: false);
        final outgoingProvider = Provider.of<OutgoingPaymentProvider>(
          context,
          listen: false,
        );

        await Future.wait([
          fetchAPInvoices(status: null, skip: 0, limit: 50),
          grnProvider.fetchFilteredGRNs(),
          outgoingProvider.fetchFilteredOutgoings(),
        ]);

        if (context.mounted) {
          AppSnackbar.showSuccess(context, 'AP returned to GRN successfully');
        }
      } else {
        throw const AppException("Return failed.");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      _setError(exception.message);

      if (context.mounted) {
        AppSnackbar.showError(context, exception);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyAPInvoice(String invoiceId) async {
    _setLoading(true);

    try {
      final response = await DioClient.dio.patch(
        '/apinvoices/verify/$invoiceId',
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        await fetchAPInvoices(skip: 0, limit: 50);

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      _setError(exception.message);

      return false;
    } finally {
      _setLoading(false);
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
}
