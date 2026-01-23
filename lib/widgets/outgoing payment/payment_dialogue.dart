// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:purchaseorders2/providers/payment_dialog_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/calculator_utils.dart';

class PaymentDialog extends StatelessWidget {
  final double totalPayableAmount;
  final bool isBulkPayment;
  final Function(
    String paymentType,
    double amount,
    String paymentMode,
    String paymentMethod,
    Map<String, dynamic> transactionDetails,
  )
  onPaymentConfirmed;

  const PaymentDialog({
    super.key,
    required this.totalPayableAmount,
    required this.onPaymentConfirmed,
    this.isBulkPayment = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentDialogProvider(
        totalPayableAmount: totalPayableAmount,
        isBulkPayment: isBulkPayment,
      ),
      child: Builder(
        builder: (context) {
          return Consumer<PaymentDialogProvider>(
            builder: (context, provider, _) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text(
                  isBulkPayment ? 'Confirm Bulk Payment' : 'Confirm Payment',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: provider.formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Payable: ${totalPayableAmount.toStringAsFixed(2)}',
                        ),
                        if (isBulkPayment) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Number of Payments: ${provider.paymentCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildPaymentTypeDropdown(provider),
                        const SizedBox(height: 16),
                        _buildAmountField(provider, context),
                        const SizedBox(height: 16),
                        _buildPaymentModeDropdown(provider),

                        // Show fields based on selected payment mode
                        if (provider.selectedPaymentMode == 'Cash') ...[
                          const SizedBox(height: 16),
                          _buildCashTypeDropdown(provider),
                        ],

                        if (provider.selectedPaymentMode == 'Bank') ...[
                          const SizedBox(height: 16),
                          ..._buildBankFields(context, provider),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildCancelButton(context, provider)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildConfirmButton(context, provider)),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentTypeDropdown(PaymentDialogProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedPaymentType,
      decoration: InputDecoration(
        labelText: 'Payment Type',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
      ),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'full', child: Text('Full Payment')),
        DropdownMenuItem(value: 'partial', child: Text('Partial Payment')),
      ],
      onChanged: (value) {
        provider.setPaymentType(value!);
        print('Selected Payment Type: $value');
        if (value == 'full') {
          provider.amountController.text = totalPayableAmount.toStringAsFixed(
            2,
          );
          print('Set amount to full: ${provider.amountController.text}');
        }
      },
      validator: (value) =>
          value == null ? 'Please select a payment type' : null,
    );
  }

  Widget _buildAmountField(
    PaymentDialogProvider provider,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        showNumericCalculator(
          context: context,
          controller: provider.amountController,
          varianceName: 'Enter Amount',
          onValueSelected: () {
            print('Amount selected: ${provider.amountController.text}');
          },
          fieldType: '',
        );
        print('Opened numeric calculator for amount');
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: provider.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
            ),
            hintText: 'Enter amount',
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            labelStyle: const TextStyle(color: Colors.black87),
            floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter an amount';
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            print('Validated amount: $value');
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildPaymentModeDropdown(PaymentDialogProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedPaymentMode,
      decoration: InputDecoration(
        labelText: 'Payment Mode',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: Colors.black87),
      ),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'Bank', child: Text('Bank')),
      ],
      onChanged: (value) {
        provider.setPaymentMode(value!);
        print('Selected Payment Mode: $value');
      },
      validator: (value) =>
          value == null ? 'Please select a payment mode' : null,
    );
  }

  Widget _buildCashTypeDropdown(PaymentDialogProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedCashType,
      decoration: InputDecoration(
        labelText: 'Cash Type',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
      ),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'petty_cash', child: Text('Petty Cash')),
        DropdownMenuItem(value: 'ho_cash', child: Text('HO Cash')),
      ],
      onChanged: (value) {
        provider.setCashType(value!);
        print('Selected Cash Type: $value');
      },
      validator: (value) => value == null ? 'Please select a cash type' : null,
    );
  }

  List<Widget> _buildBankFields(
    BuildContext context,
    PaymentDialogProvider provider,
  ) {
    return [
      // 🔄 BANK LIST / ERROR / AUTOCOMPLETE
      provider.isLoadingBanks
          ? const Center(child: CircularProgressIndicator())
          : provider.bankError != null
          ? Column(
              children: [
                Text(
                  provider.bankError!,
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: () {
                    provider.fetchBanks();
                  },
                  child: const Text('Retry'),
                ),
              ],
            )
          : Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return provider.banks.map((b) => b.bankName);
                }
                return provider.banks
                    .map((b) => b.bankName)
                    .where(
                      (name) => name.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
              },

              onSelected: (String selection) {
                provider.setBankName(selection);
              },

              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.text, // ✅ normal keyboard
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        suffixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a bank'
                          : null,
                    );
                  },

              optionsViewBuilder:
                  (
                    BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        color: Colors.white, // ✅ DROPDOWN BACKGROUND WHITE
                        child: SizedBox(
                          height: 200,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                tileColor: Colors.white, // ✅ EACH ITEM WHITE
                                title: Text(
                                  option,
                                  style: const TextStyle(color: Colors.black),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
            ),

      const SizedBox(height: 16),

      // 💳 BANK PAYMENT METHOD
      DropdownButtonFormField<String>(
        initialValue: provider.selectedBankPaymentMethod,
        decoration: InputDecoration(
          labelText: 'Bank Payment Method',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black54),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: const [
          DropdownMenuItem(value: 'neft', child: Text('NEFT')),
          DropdownMenuItem(value: 'rtgs', child: Text('RTGS')),
          DropdownMenuItem(value: 'imps', child: Text('IMPS')),
          DropdownMenuItem(value: 'upi', child: Text('UPI')),
        ],
        onChanged: (value) {
          provider.setBankPaymentMethod(value!);
        },
        validator: (value) =>
            value == null ? 'Please select a payment method' : null,
      ),

      const SizedBox(height: 16),

      // 🧾 TRANSACTION FIELD (UPI vs OTHERS)
      provider.selectedBankPaymentMethod == 'upi'
          // ✅ UPI → NORMAL KEYBOARD
          ? TextFormField(
              controller: provider.transactionController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'UPI ID / Reference',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter UPI reference'
                  : null,
            )
          // ✅ NEFT / RTGS / IMPS → NUMERIC CALCULATOR
          : GestureDetector(
              onTap: () {
                showNumericCalculator(
                  context: context,
                  controller: provider.transactionController,
                  varianceName: 'Enter Reference Number',
                  onValueSelected: () {},
                  fieldType: '',
                );
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: provider.transactionController,
                  decoration: InputDecoration(
                    labelText: provider.getTransactionLabel(),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter reference number'
                      : null,
                ),
              ),
            ),
    ];
  }

  Widget _buildCancelButton(
    BuildContext context,
    PaymentDialogProvider provider,
  ) {
    return OutlinedButton(
      onPressed: () {
        provider.resetFields();
        Navigator.of(context).pop();
        print('Payment dialog cancelled');
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blue),
        foregroundColor: Colors.blue,
        minimumSize: const Size(double.infinity, 45),
      ),
      child: const Text('Cancel'),
    );
  }

  Widget _buildTransactionField(
    BuildContext context,
    PaymentDialogProvider provider,
  ) {
    final bool isUPI = provider.selectedBankPaymentMethod == 'upi';

    // ✅ UPI → NORMAL MOBILE KEYBOARD
    if (isUPI) {
      return TextFormField(
        controller: provider.transactionController,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: 'UPI Reference / UTR',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black54),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value == null || value.isEmpty
            ? 'Please enter UPI reference'
            : null,
      );
    }

    // ✅ NEFT / RTGS / IMPS → NUMERIC CALCULATOR
    return GestureDetector(
      onTap: () {
        showNumericCalculator(
          context: context,
          controller: provider.transactionController,
          varianceName: 'Enter Reference Number',
          onValueSelected: () {},
          fieldType: '',
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: provider.transactionController,
          decoration: InputDecoration(
            labelText: provider.getTransactionLabel(),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter reference number'
              : null,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    PaymentDialogProvider provider,
  ) {
    return SizedBox(
      width: double.infinity, // ✅ Use full width without LayoutBuilder
      height: 48, // ✅ Consistent tap height
      child: ElevatedButton(
        onPressed: provider.isSubmitting
            ? null
            : () async {
                if (!provider.formKey.currentState!.validate()) return;

                final bool? shouldConfirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white, // ✅ Dialog white
                    title: const Text(
                      'Confirm Payment',
                      textAlign: TextAlign.center,
                    ),
                    content: Text(
                      'Are you sure you want to proceed with the payment of '
                      '${provider.getAmount().toStringAsFixed(2)}?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                    ),
                    actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    actions: [
                      Row(
                        children: [
                          // ❌ CANCEL (Blue Accent Outline)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.blueAccent,
                                ),
                                foregroundColor: Colors.blueAccent,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ✅ CONFIRM (Blue Accent Filled, White Text)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white, // ✅ Text white
                              ),
                              child: const Text('Confirm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (shouldConfirm != true) return;

                provider.setSubmitting(true);

                try {
                  final Map<String, dynamic> transactionDetails = {};

                  if (provider.selectedPaymentMode == 'Bank') {
                    transactionDetails.addAll({
                      'bankName': provider.selectedBankName,
                      if (provider.selectedBankPaymentMethod == 'neft')
                        'neftNo': provider.transactionController.text,
                      if (provider.selectedBankPaymentMethod == 'rtgs')
                        'rtgsNo': provider.transactionController.text,
                      if (provider.selectedBankPaymentMethod == 'imps')
                        'impsNo': provider.transactionController.text,
                      if (provider.selectedBankPaymentMethod == 'upi')
                        'upi': provider.transactionController.text,
                    });
                  } else {
                    transactionDetails.addAll({
                      if (provider.selectedCashType == 'petty_cash')
                        'pettyCashAmount': provider.getAmount(),
                      if (provider.selectedCashType == 'ho_cash')
                        'hoCash': provider.getAmount(),
                    });
                  }

                  final backendPaymentMethod =
                      provider.selectedPaymentMode == 'Bank'
                      ? provider.selectedBankPaymentMethod
                      : provider.selectedCashType;

                  await onPaymentConfirmed(
                    provider.selectedPaymentType,
                    provider.getAmount(),
                    provider.selectedPaymentMode,
                    backendPaymentMethod,
                    transactionDetails,
                  );

                  provider.resetFields();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } finally {
                  provider.setSubmitting(false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // ✅ modern look
          ),
        ),
        child: provider.isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Center(
                child: Text(
                  isBulkPayment ? 'Confirm Bulk Payment' : 'Confirm Payment',
                  textAlign: TextAlign.center, // ✅ CENTER ALIGN
                  softWrap: true, // ✅ ALLOW WRAP
                  maxLines: 2, // ✅ NO CUT
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
