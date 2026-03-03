// ignore_for_file: avoid_print

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/bankdetails_models.dart';

class PaymentDialogProvider with ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final double _totalPayableAmount;
  final bool _isBulkPayment;
  final ValueNotifier<String> paymentType = ValueNotifier<String>('full');
  final ValueNotifier<String> paymentMode = ValueNotifier<String>('Cash');
  final ValueNotifier<String> cashType = ValueNotifier<String>('petty_cash');
  final ValueNotifier<String> bankPaymentMethod = ValueNotifier<String>('neft');
  final ValueNotifier<String?> bankName = ValueNotifier<String?>(null);
  final ValueNotifier<double> amountNotifier = ValueNotifier<double>(0.0);
  final TextEditingController amountController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController transactionController = TextEditingController();

  List<Bank> _banks = [];
  bool _isLoadingBanks = false;
  String? _bankError;
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  PaymentDialogProvider({
    required double totalPayableAmount,
    required bool isBulkPayment,
  }) : _totalPayableAmount = totalPayableAmount,
       _isBulkPayment = isBulkPayment {
    amountNotifier.value = _totalPayableAmount;
    amountController.text = _totalPayableAmount.toStringAsFixed(2);
  }

  double get totalPayableAmount => _totalPayableAmount;
  bool get isBulkPayment => _isBulkPayment;
  String get selectedPaymentType => paymentType.value;
  String get selectedPaymentMode => paymentMode.value;
  String get selectedCashType => cashType.value;
  String get selectedBankPaymentMethod => bankPaymentMethod.value;
  String? get selectedBankName => bankName.value;
  List<Bank> get banks => _banks;
  bool get isLoadingBanks => _isLoadingBanks;
  String? get bankError => _bankError;

  int get paymentCount {
    if (!_isBulkPayment) return 1;
    if (paymentType.value == 'full') return 1;
    final amt = amountNotifier.value;
    return amt <= 0 ? 0 : (_totalPayableAmount / amt).ceil();
  }

  void setPaymentType(String value) {
    if (paymentType.value == value) return;

    paymentType.value = value;

    if (value == 'full') {
      amountNotifier.value = _totalPayableAmount;
      amountController.text = _totalPayableAmount.toStringAsFixed(2);
    } else {
      amountNotifier.value = 0.0;
      amountController.clear();
    }

    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void setPaymentMode(String value) {
    if (paymentMode.value == value) return;

    paymentMode.value = value;

    if (value == 'Bank') {
      fetchBanks();

      cashType.value = 'petty_cash';
    } else {
      bankName.value = null;
      bankNameController.clear();
      transactionController.clear();
      bankPaymentMethod.value = 'neft';

      _bankError = null;
    }

    notifyListeners();
  }

  void setCashType(String value) {
    if (cashType.value == value) return;
    cashType.value = value;
    notifyListeners();
  }

  void setBankPaymentMethod(String value) {
    if (bankPaymentMethod.value == value) return;

    bankPaymentMethod.value = value;
    transactionController.clear();
    notifyListeners();
  }

  void setBankName(String? name) {
    if (bankName.value == name) return;

    bankName.value = name;
    bankNameController.text = name ?? '';
    notifyListeners();
  }

  void setAmount(double value) {
    amountNotifier.value = value;
    amountController.text = value == 0 ? '' : value.toStringAsFixed(2);
    notifyListeners();
  }

  double getAmount() {
    if (amountNotifier.value > 0) return amountNotifier.value;

    final parsed = double.tryParse(amountController.text) ?? 0.0;
    return parsed;
  }

  String getTransactionLabel() {
    if (paymentMode.value == 'Cash') {
      return 'Cash Payment';
    }
    switch (bankPaymentMethod.value) {
      case 'neft':
        return 'NEFT Reference Number';
      case 'rtgs':
        return 'RTGS Reference Number';
      case 'imps':
        return 'IMPS Reference Number';
      case 'upi':
        return 'UPI Transaction ID';
      default:
        return 'Transaction Number';
    }
  }

  void resetFields() {
    paymentType.value = 'full';
    paymentMode.value = 'Cash';
    cashType.value = 'petty_cash';
    bankPaymentMethod.value = 'neft';
    bankName.value = null;

    amountNotifier.value = _totalPayableAmount;
    amountController.text = _totalPayableAmount.toStringAsFixed(2);

    bankNameController.clear();
    transactionController.clear();

    _bankError = null;
    _isLoadingBanks = false;
    _isSubmitting = false;
    notifyListeners();
  }

  Future<void> fetchBanks() async {
    if (_isLoadingBanks || _banks.isNotEmpty) {
      return;
    }

    _isLoadingBanks = true;
    _bankError = null;
    notifyListeners();

    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 10)
        ..options.receiveTimeout = const Duration(seconds: 10);

      final response = await dio.get(
        'https://yenerp.com/masterapi/bankmasters/',
      );

      if (response.statusCode == 200) {
        _banks = (response.data as List)
            .map((json) => Bank.fromJson(json))
            .toList();

        if (_banks.isNotEmpty) {
          bankName.value = _banks.first.bankName;
          bankNameController.text = bankName.value ?? '';
        }
      } else {
        _bankError = 'Server error: ${response.statusCode}';
      }
    } on DioException catch (e) {
      _bankError = 'Failed to load banks: ${e.message}';
    } finally {
      _isLoadingBanks = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    paymentType.dispose();
    paymentMode.dispose();
    cashType.dispose();
    bankPaymentMethod.dispose();
    bankName.dispose();
    amountNotifier.dispose();
    amountController.dispose();
    bankNameController.dispose();
    transactionController.dispose();
    super.dispose();
  }
}
