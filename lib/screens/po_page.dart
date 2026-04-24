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
        onRefresh: _refreshPOs,
        child: Consumer<POProvider>(
          builder: (context, poProvider, _) {
            final pendingOrders = poProvider.pendingPOs;


            // ✅ First loading
            if (poProvider.isLoading && pendingOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (poProvider.error != null && pendingOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 10),

                        /// ✅ USER FRIENDLY MESSAGE
                        Text(
                          poProvider.error ?? "Something went wrong",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        /// 🔁 RETRY BUTTON
                        ElevatedButton(
                          onPressed: _refreshPOs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ✅ Empty
            if (!poProvider.isLoading && pendingOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No pending purchase orders available.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            // ✅ DATA UI (FIXED)
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
