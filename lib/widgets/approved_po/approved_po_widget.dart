import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/widgets/approved_po/approved_po_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ApprovedPOWidget extends StatefulWidget {
  final PO po;
  final POProvider poProvider;

  const ApprovedPOWidget({
    super.key,
    required this.po,
    required this.poProvider,
  });

  @override
  State<ApprovedPOWidget> createState() => _ApprovedPOWidgetState();
}

class _ApprovedPOWidgetState extends State<ApprovedPOWidget> {
  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ApprovedPODialog(
          po: widget.po,
          poProvider: widget.poProvider,
          onUpdated: () async {
            final provider = Provider.of<POProvider>(context, listen: false);
            await provider.fetchApprovedPOsOnly();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POProvider>();
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),

      // ✅ ONLY BLUE HEADER (NO EMPTY SPACE)
      child: _buildHeader(provider),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(POProvider provider) {
    final po = widget.po;
    final statusText = _formatStatus(po.poStatus);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== ROW 1: PO NO + STATUS =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "PO No: ${po.randomId ?? "N/A"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ✅ STATUS BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ===== ROW 2: VENDOR + ACTIONS =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Vendor: ${po.vendorName ?? "N/A"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                    onPressed: () => _showItemDetails(context),
                  ),
                  provider.isPdfLoading(widget.po.purchaseOrderId)
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            context.read<POProvider>().generatePdf(
                              widget.po,
                              context,
                            );
                          },
                        ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ===== ROW 3: AMOUNT + DATE =====
          Row(
            children: [
              Expanded(
                child: Text(
                  "Amount: ${(po.pendingOrderAmount ?? 0).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  "Date: ${po.orderDate != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(po.orderDate!)) : "N/A"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STATUS FORMAT =================

  String _formatStatus(String? status) {
    if (status == null) return "Unknown";

    switch (status) {
      case "Approved":
        return "Approved";
      case "PartiallyReceived":
        return "Partially Received";

      default:
        return status;
    }
  }
}
