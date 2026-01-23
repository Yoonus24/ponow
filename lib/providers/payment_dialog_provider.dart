// ignore_for_file: avoid_print

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/bankdetails_models.dart';

class PaymentDialogProvider with ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Base values (normal fields)
  final double _totalPayableAmount;
  final bool _isBulkPayment;

  // --- Reactive state using ValueNotifier ---
  // (Use these in UI with ValueListenableBuilder)

  /// 'full' | 'partial'
  final ValueNotifier<String> paymentType = ValueNotifier<String>('full');

  /// 'Cash' | 'Bank'
  final ValueNotifier<String> paymentMode = ValueNotifier<String>('Cash');

  /// 'petty_cash' | 'ho_cash'
  final ValueNotifier<String> cashType = ValueNotifier<String>('petty_cash');

  /// 'neft' | 'rtgs' | 'imps' | 'upi'
  final ValueNotifier<String> bankPaymentMethod = ValueNotifier<String>('neft');

  /// Selected bank name (nullable)
  final ValueNotifier<String?> bankName = ValueNotifier<String?>(null);

  /// Amount selected/entered
  final ValueNotifier<double> amountNotifier = ValueNotifier<double>(0.0);

  // Controllers (for TextFormFields)
  final TextEditingController amountController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController transactionController = TextEditingController();

  // Bank list
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
    // Initial state → full payment
    amountNotifier.value = _totalPayableAmount;
    amountController.text = _totalPayableAmount.toStringAsFixed(2);

    print(
      'PaymentDialogProvider initialized with totalPayableAmount: $_totalPayableAmount, '
      'isBulkPayment: $_isBulkPayment',
    );
  }

  // ---------------------------------------------------------------------------
  // GETTERS (read-only for external usage)
  // ---------------------------------------------------------------------------

  double get totalPayableAmount => _totalPayableAmount;
  bool get isBulkPayment => _isBulkPayment;

  // For backward compatibility if somewhere you used provider.selectedPaymentType
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

  // ---------------------------------------------------------------------------
  // STATE MUTATORS – all via ValueNotifier
  // ---------------------------------------------------------------------------

  void setPaymentType(String value) {
    if (paymentType.value == value) return;

    paymentType.value = value;
    print('Set payment type: ${paymentType.value}');

    if (value == 'full') {
      // Full payment = total payable
      amountNotifier.value = _totalPayableAmount;
      amountController.text = _totalPayableAmount.toStringAsFixed(2);
    } else {
      // Partial → amount user-entered / from calculator
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
    print('Set payment mode: ${paymentMode.value}');

    if (value == 'Bank') {
      // Load bank list (can call notifyListeners inside)
      fetchBanks();

      // Clear cash type fields when switching to Bank
      cashType.value = 'petty_cash'; // Reset to default
    } else {
      // Cash → reset bank related fields
      bankName.value = null;
      bankNameController.clear();
      transactionController.clear();
      bankPaymentMethod.value = 'neft'; // Reset to default

      // Clear any existing bank error
      _bankError = null;
    }

    notifyListeners();
  }

  void setCashType(String value) {
    if (cashType.value == value) return;
    cashType.value = value;
    print('Set cash type: ${cashType.value}');
    notifyListeners();
  }

  void setBankPaymentMethod(String value) {
    if (bankPaymentMethod.value == value) return;

    bankPaymentMethod.value = value;
    transactionController.clear();

    print(
      'Set bank payment method: ${bankPaymentMethod.value}, '
      'cleared transaction controller',
    );

    notifyListeners();
  }

  void setBankName(String? name) {
    if (bankName.value == name) return;

    bankName.value = name;
    bankNameController.text = name ?? '';
    print('Set bank name: ${bankName.value}');
    notifyListeners();
  }

  /// When user selects amount from numeric keypad / text field
  void setAmount(double value) {
    amountNotifier.value = value;
    amountController.text = value == 0 ? '' : value.toStringAsFixed(2);
    print('Updated amount: $value');
    notifyListeners();
  }

  double getAmount() {
    // Prefer notifier; fallback to controller if needed
    if (amountNotifier.value > 0) return amountNotifier.value;

    final parsed = double.tryParse(amountController.text) ?? 0.0;
    print('Retrieved amount (parsed): $parsed');
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

    // Reset bank-related states
    _bankError = null;
    _isLoadingBanks = false;
    _isSubmitting = false;

    print('Reset all fields to default values');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // BANK FETCH
  // ---------------------------------------------------------------------------

  Future<void> fetchBanks() async {
    // Don't fetch if already loading or already fetched
    if (_isLoadingBanks || _banks.isNotEmpty) {
      return;
    }

    _isLoadingBanks = true;
    _bankError = null;
    print('Fetching banks...');
    notifyListeners(); // UI for loader

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

        print('Fetched ${_banks.length} banks successfully');

        if (_banks.isNotEmpty) {
          bankName.value = _banks.first.bankName;
          bankNameController.text = bankName.value ?? '';
          print('Set default bank name: ${bankName.value}');
        }
      } else {
        _bankError = 'Server error: ${response.statusCode}';
        print('Bank fetch failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _bankError = 'Failed to load banks: ${e.message}';
      print('Bank fetch error: ${e.message}');
    } finally {
      _isLoadingBanks = false;
      print('Bank fetch completed, isLoadingBanks: $_isLoadingBanks');
      notifyListeners(); // to rebuild loader/bank list
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    print('Disposing PaymentDialogProvider');

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
