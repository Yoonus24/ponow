import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/po/po.dart';
import '../../providers/po/po_provider.dart';
import 'po_widget.dart';

class POListView extends StatelessWidget {
  final List<PO> purchaseOrders;
  final ScrollController scrollController;
  final VoidCallback? onStatusChanged;

  const POListView({
    super.key,
    required this.purchaseOrders,
    required this.scrollController,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final poProvider = Provider.of<POProvider>(context);

    final mq = MediaQuery.of(context);
    final double bottomNavHeight = mq.size.height * 0.010;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth ~/ 300;
        if (columns < 1) columns = 1;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomNavHeight + mq.padding.bottom),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: purchaseOrders.map((po) {
              final isSelected = poProvider.selectedPO?.randomId == po.randomId;

              return SizedBox(
                width: constraints.maxWidth / columns - 16,
                child: POWidget(
                  po: po,
                  isSelected: isSelected,
                  onStatusChanged: onStatusChanged,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
