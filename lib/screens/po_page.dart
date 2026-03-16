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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<POProvider>();

      if (!_isInitialized) {
        if (provider.pendingPOs.isEmpty) {
          provider.refreshPOList();
        }

        _isInitialized = true;
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
            final pendingOrders = poProvider.pendingPOs;

            // ✅ Show loader first time only
            if (poProvider.isLoading && pendingOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ Show error only if no data
            if (poProvider.error != null && pendingOrders.isEmpty) {
              return Center(
                child: Text(
                  poProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            // ✅ Show empty only after loading finished
            if (!poProvider.isLoading && pendingOrders.isEmpty) {
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

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                // 🔹 Small loader when refreshing
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
                  key: const PageStorageKey("po_list"),
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
