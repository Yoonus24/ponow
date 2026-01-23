import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/outgoing.dart';

class PendingOutgoingDialog extends StatelessWidget {
  final Outgoing outgoing;

  const PendingOutgoingDialog({super.key, required this.outgoing});

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.85;

    // ✅ TRUST BACKEND VALUES (same as list screen)
    final paidAmount = outgoing.totalPaidAmount ?? 0.0;
    final remainingAmount = outgoing.totalPayableAmount ?? 0.0;

    final sgstTotal = _calculateTotalSGST();
    final cgstTotal = _calculateTotalCGST();
    final igstTotal = _calculateTotalIGST();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxWidth: 450, minWidth: 280),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(thickness: 1),
              _buildDetails(
                paidAmount,
                remainingAmount,
                sgstTotal,
                cgstTotal,
                igstTotal,
              ),
              const SizedBox(height: 16),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Outgoing Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Details List =====
  Widget _buildDetails(
    double paidAmount,
    double remainingAmount,
    double sgstTotal,
    double cgstTotal,
    double igstTotal,
  ) {
    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              ' : ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Vendor', outgoing.vendorName ?? 'N/A'),
        row('Invoice No', outgoing.invoiceNo ?? 'N/A'),
        row('Date', _formatDate(outgoing.invoiceDate)),
        row('Total Amount', _formatCurrency(outgoing.totalPrice)),
        row('Discount', _formatCurrency(outgoing.discountDetails)),
        row('Tax', _formatCurrency(outgoing.taxDetails)),
        row('SGST', _formatCurrency(sgstTotal)),
        row('CGST', _formatCurrency(cgstTotal)),
        row('IGST', _formatCurrency(igstTotal)),
        row('Payable', _formatCurrency(outgoing.payableAmount)),
        row('Paid', _formatCurrency(paidAmount)),
        row('Remaining', _formatCurrency(remainingAmount)),
        row('Due Days', outgoing.intimationDays?.toString() ?? 'N/A'),
        row('Payment Terms', outgoing.paymentTerms ?? 'N/A'),
      ],
    );
  }

  // ===== Close Button =====
  Widget _buildCloseButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text('Close', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  // ===== Tax Calculations =====
  double _calculateTotalSGST() {
    return outgoing.itemDetails?.fold<double>(
          0.0,
          (sum, item) => sum + (item.sgst ?? 0.0),
        ) ??
        0.0;
  }

  double _calculateTotalCGST() {
    return outgoing.itemDetails?.fold<double>(
          0.0,
          (sum, item) => sum + (item.cgst ?? 0.0),
        ) ??
        0.0;
  }

  double _calculateTotalIGST() {
    return outgoing.itemDetails?.fold<double>(
          0.0,
          (sum, item) => sum + (item.igst ?? 0.0),
        ) ??
        0.0;
  }

  // ===== Format Helpers =====
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _formatCurrency(num? amount) {
    if (amount == null) return 'N/A';
    try {
      return NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount);
    } catch (_) {
      return amount.toString();
    }
  }
}
