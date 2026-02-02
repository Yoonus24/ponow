import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/po page/po_list_view.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';

class POPage extends StatefulWidget {
  const POPage({super.key});

  @override
  State<POPage> createState() => _POPageState();
}

class _POPageState extends State<POPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<POProvider>().refreshPOList();
        context.read<PurchaseOrderNotifier>().fetchAllVendors1();
      }
    });
  }

  Future<void> _refreshPOs() async {
    await context.read<POProvider>().refreshPOList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Pending Purchase Orders'),
      body: RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: _refreshPOs,
        child: Consumer<POProvider>(
          builder: (context, poProvider, _) {
            // 🔄 Loading
            if (poProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // ❌ Error
            if (poProvider.error != null) {
              return ListView(
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Text(
                      'Error: ${poProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            // 📦 Filter pending POs
            final pendingOrders = poProvider.pos.where((po) {
              return po.poStatus == 'Pending' ||
                  po.poStatus == 'Pending for Approve' ||
                  po.poStatus == 'CreditLimit for Approve';
            }).toList();

            // 📭 EMPTY STATE — ORIGINAL STYLE
            if (pendingOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), 
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No pending purchase orders available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                POListView(
                  purchaseOrders: pendingOrders,
                  scrollController: _scrollController,
                  onStatusChanged: _refreshPOs,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
