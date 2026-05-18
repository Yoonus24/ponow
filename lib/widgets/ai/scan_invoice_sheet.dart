import 'package:flutter/material.dart';

class ScanInvoiceSheet extends StatelessWidget {
  const ScanInvoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const _DragHandle(),

          const SizedBox(height: 20),

          // Header Section
          const _HeaderSection(),

          const SizedBox(height: 8),

          // Subtitle
          const _SubtitleSection(),

          const SizedBox(height: 32),

          // Action Cards
          const _ActionCardsSection(),

          // Bottom Spacing
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}

// Separate widget for drag handle - improves rebuild efficiency
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: const Center(child: _DragHandleBar()),
    );
  }
}

class _DragHandleBar extends StatelessWidget {
  const _DragHandleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// Header section - optimized with const
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "AI Invoice Assistant",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Subtitle section - optimized
class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Let AI help you scan and process invoices",
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF6B7280), // Direct color for better performance
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Action cards section - optimized with memoization pattern
class _ActionCardsSection extends StatelessWidget {
  const _ActionCardsSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.camera_alt_rounded,
              iconColor: Color(0xFF6366F1),
              label: "AI Scan",
              subtitle: "Smart Camera Capture",
              value: "camera",
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.upload_file_rounded,
              iconColor: Color(0xFF10B981),
              label: "AI Upload",
              subtitle: "Smart Document Processing",
              value: "gallery",
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized card widget - uses const constructor and minimal rebuilds
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String value;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Prevents unnecessary repaints
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.pop(context, value),
          borderRadius: BorderRadius.circular(24),
          splashColor: iconColor.withOpacity(0.12),
          highlightColor: iconColor.withOpacity(0.06),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconContainer(icon: icon, color: iconColor),
                const SizedBox(height: 18),
                _CardLabel(label: label),
                const SizedBox(height: 6),
                _CardSubtitle(subtitle: subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Separate icon container for better performance
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconContainer({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }
}

// Optimized label widget
class _CardLabel extends StatelessWidget {
  final String label;

  const _CardLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Optimized subtitle widget
class _CardSubtitle extends StatelessWidget {
  final String subtitle;

  const _CardSubtitle({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Extension for better theme management
extension ThemeColors on Color {
  static const Color primary = Color(0xFF6366F1);
  static const Color success = Color(0xFF10B981);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}
