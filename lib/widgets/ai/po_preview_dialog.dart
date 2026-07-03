import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po/po.dart';

class POPreviewDialog extends StatelessWidget {
  final PO po;

  const POPreviewDialog({super.key, required this.po});

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "approved":
        return const Color(0xFF10B981);
      case "pending":
        return const Color(0xFFF59E0B);
      case "rejected":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "-";

    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt,
                      color: Color(0xFF3B82F6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Purchase Order Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 22),
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info - 2 Column Layout
                    _buildInfoSection(),

                    const SizedBox(height: 24),

                    // Items Section
                    const Text(
                      "Order Items",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items Table
                    _buildItemsTable(context),

                    const SizedBox(height: 24),

                    // Additional Information
                    const Text(
                      "Additional Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow("Payment Terms", po.paymentTerms ?? "-"),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      "Shipping Address",
                      po.shippingAddress ?? "-",
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow("Billing Address", po.billingAddress ?? "-"),
                    const SizedBox(height: 12),
                    _buildInfoRow("Location", po.location ?? "-"),

                    if (po.comments != null && po.comments!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow("Comments", po.comments!),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Row 1
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow("PO Number", po.randomId ?? "-"),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow("Vendor Name", po.vendorName ?? "-"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    "Status",
                    po.poStatus ?? "-",
                    isStatus: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow(
                    "Order Date",
                    _formatDate(po.orderDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 3
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    "Expected Delivery",
                    _formatDate(po.expectedDeliveryDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow(
                    "Total Amount",
                    "₹${po.totalOrderAmount ?? 0}",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(value),
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    final items = po.items;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: screenWidth > 1200 ? screenWidth - 80 : 1300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    _buildHeaderCell("No", flex: 50),
                    _buildHeaderCell("Item Name", flex: 200),
                    _buildHeaderCell("UOM", flex: 70),
                    _buildHeaderCell("Qty", flex: 70, alignRight: true),
                    _buildHeaderCell("Pkt Count", flex: 80, alignRight: true),
                    _buildHeaderCell("Each Qty", flex: 80, alignRight: true),
                    _buildHeaderCell(
                      "Pending\nQty",
                      flex: 90,
                      alignRight: true,
                    ),
                    _buildHeaderCell(
                      "Existing\nPrice",
                      flex: 90,
                      alignRight: true,
                    ),
                    _buildHeaderCell("New\nPrice", flex: 80, alignRight: true),
                    _buildHeaderCell("Tax %", flex: 70, alignRight: true),
                    _buildHeaderCell(
                      "Total Price\n(Incl. Tax)",
                      flex: 100,
                      alignRight: true,
                    ),
                  ],
                ),
              ),

              // Table Rows
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: index != items.length - 1
                        ? const Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      _buildDataCell((index + 1).toString(), flex: 50),
                      _buildDataCell(item.itemName ?? "-", flex: 200),
                      _buildDataCell(item.uom ?? "-", flex: 70),
                      _buildDataCell(
                        (item.quantity ?? 0).toStringAsFixed(2),
                        flex: 70,
                        alignRight: true,
                      ),
                      _buildDataCell(
                        (item.count ?? 0).toStringAsFixed(2),
                        flex: 80,
                        alignRight: true,
                      ),
                      _buildDataCell(
                        (item.eachQuantity ?? 0).toStringAsFixed(2),
                        flex: 80,
                        alignRight: true,
                      ),
                      // Pending Qty - placed right after Each Qty
                      _buildDataCell(
                        (item.pendingTotalQuantity ?? 0).toStringAsFixed(2),
                        flex: 90,
                        alignRight: true,
                        isPending: true,
                      ),
                      _buildDataCell(
                        "₹${(item.existingPrice ?? 0).toStringAsFixed(2)}",
                        flex: 90,
                        alignRight: true,
                      ),
                      _buildDataCell(
                        "₹${(item.newPrice ?? 0).toStringAsFixed(2)}",
                        flex: 80,
                        alignRight: true,
                        isNewPrice: true,
                      ),
                      _buildDataCell(
                        "${(item.taxPercentage ?? 0).toStringAsFixed(2)}%",
                        flex: 70,
                        alignRight: true,
                      ),
                      // Using finalPrice (including tax) instead of totalPrice
                      _buildDataCell(
                        "₹${(item.finalPrice ?? 0).toStringAsFixed(2)}",
                        flex: 100,
                        alignRight: true,
                        isTotal: true,
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 710, child: Container()),
                    _buildHeaderCell("Total:", flex: 100, alignRight: true),
                    // Calculating total using finalPrice (including tax)
                    _buildDataCell(
                      "₹${_calculateTotalWithTax().toStringAsFixed(2)}",
                      flex: 100,
                      alignRight: true,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to calculate total with tax (using finalPrice)
  double _calculateTotalWithTax() {
    return po.items.fold(0.0, (sum, item) => sum + (item.finalPrice ?? 0));
  }

  Widget _buildHeaderCell(
    String text, {
    int flex = 1,
    bool alignRight = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    int flex = 1,
    bool alignRight = false,
    bool isTotal = false,
    bool isPending = false,
    bool isNewPrice = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isTotal || isNewPrice || isPending
              ? FontWeight.w600
              : FontWeight.normal,
          color: isTotal
              ? const Color(0xFF3B82F6)
              : isNewPrice
              ? const Color(0xFF10B981)
              : isPending
              ? const Color(0xFFF59E0B)
              : const Color(0xFF1F2937),
        ),
      ),
    );
  }

  double _calculateTotal() {
    return po.items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0));
  }
}
