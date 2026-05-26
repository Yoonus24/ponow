import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/connectivity_provider.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        final bool showOffline = !connectivityProvider.isConnected;
        final bool showOnline = connectivityProvider.showBackOnline;

        return Stack(
          children: [
            child,

            /// 🔴 Offline / 🟢 Online Banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 16,
              right: 16,
              bottom: (showOffline || showOnline)
                  ? kBottomNavigationBarHeight + bottomInset + 32.0
                  : -100.0,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(30),
                color: showOffline
                    ? Colors.grey.shade900
                    : Colors.green.shade600,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showOffline ? Icons.wifi_off : Icons.wifi,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showOffline ? 'You are offline' : 'Back online',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
