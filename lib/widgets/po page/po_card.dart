import 'package:flutter/material.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:provider/provider.dart';
import '../../models/po.dart';

class POCard extends StatelessWidget {
  final PO po;
  final GlobalKey cardKey; // ✅ Accept GlobalKey as parameter

  const POCard({
    super.key,
    required this.po,
    required this.cardKey, // ✅ Required parameter
  });

  void scrollToPO() {
    final context = cardKey.currentContext; // ✅ Now this works with GlobalKey

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<POProvider>(context);
    final isSelected = poProvider.selectedPO?.randomId == po.randomId;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          poProvider.setSelectedPO(null);
        } else {
          poProvider.setSelectedPO(po);
          scrollToPO();
        }
      },
      child: Container(
        key: cardKey, // ✅ Use the provided GlobalKey
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected
              ? null
              : const Color.fromARGB(255, 74, 122, 227),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Center(
          child: Text(
            ' ${po.randomId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}