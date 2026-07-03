import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
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
      if (!mounted) return;

      final provider = context.read<POProvider>();

      // Fetch only first time
      if (!provider.isFirstLoadCompleted) {
        provider.refreshPOList();
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

            // Initial Loading
            if (!poProvider.isFirstLoadCompleted ||
                (poProvider.isLoading && pendingOrders.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (poProvider.error != null && pendingOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(poProvider.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshPOs,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Empty
            if (pendingOrders.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: const Center(
                        child: Text(
                          "No pending orders available.",
                          style: TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // Data
            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
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
