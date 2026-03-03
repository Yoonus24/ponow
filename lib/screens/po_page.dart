import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/po page/po_list_view.dart';

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
      context.read<POProvider>().refreshPOList();
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
            // ✅ FIX 1: use pendingPOs instead of pos
            if (poProvider.isLoading && poProvider.pendingPOs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final pendingOrders = poProvider.pendingPOs;

            // ✅ FIX 2: show empty FIRST (important)
            if (pendingOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No pending purchase orders available.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            // ✅ FIX 3: error should not override empty state
            if (poProvider.error != null) {
              return Center(
                child: Text(
                  poProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                if (poProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

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
