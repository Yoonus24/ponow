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

          // Action Cards - Static Horizontal Row
          const _ActionCardsSection(),

          // Bottom Spacing
          SizedBox(
            height:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
          ),
        ],
      ),
    );
  }
}

// Drag handle widget
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

// Header section
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 380 ? 28.0 : 32.0;
    final fontSize = screenWidth < 380
        ? 20.0
        : screenWidth < 600
        ? 24.0
        : 28.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: const Color(0xFF6366F1),
            size: iconSize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "AI Invoice Assistant",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
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

// Subtitle section
class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 380 ? 13.0 : 14.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Let AI help you scan and process invoices",
          style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF6B7280),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Action cards section - Static Horizontal Row (No Scroll)
class _ActionCardsSection extends StatelessWidget {
  const _ActionCardsSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 20.0;
    final gap = screenWidth < 400 ? 8.0 : 12.0;

    // Calculate available width for cards
    final availableWidth = screenWidth - (horizontalPadding * 2);

    // Each card gets equal width with gaps
    final cardWidth = (availableWidth - (gap * 2)) / 3;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Camera Card
          SizedBox(
            width: cardWidth,
            child: _QuickActionCard(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF6366F1),
              label: "AI Scan",
              subtitle: "Smart Capture",
              value: "camera",
            ),
          ),

          // Gallery Card
          SizedBox(
            width: cardWidth,
            child: _QuickActionCard(
              icon: Icons.image_rounded,
              iconColor: const Color(0xFF10B981),
              label: "Gallery",
              subtitle: "Upload Image",
              value: "gallery",
            ),
          ),

          // PDF Card
          SizedBox(
            width: cardWidth,
            child: _QuickActionCard(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFE53935),
              label: "PDF",
              subtitle: "Upload PDF",
              value: "pdf",
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized card widget - Responsive
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 380;
    final isSmall = screenWidth < 480;

    final verticalPadding = isVerySmall
        ? 16.0
        : isSmall
        ? 18.0
        : 20.0;
    final horizontalPadding = isVerySmall
        ? 6.0
        : isSmall
        ? 8.0
        : 10.0;
    final iconSize = isVerySmall
        ? 24.0
        : isSmall
        ? 28.0
        : 32.0;
    final iconContainerPadding = isVerySmall
        ? 10.0
        : isSmall
        ? 12.0
        : 14.0;
    final labelFontSize = isVerySmall
        ? 12.0
        : isSmall
        ? 13.0
        : 14.0;
    final subtitleFontSize = isVerySmall
        ? 10.0
        : isSmall
        ? 11.0
        : 11.5;
    final gapSize = isVerySmall ? 8.0 : 10.0;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pop(context, value),
          borderRadius: BorderRadius.circular(20),
          splashColor: iconColor.withOpacity(0.12),
          highlightColor: iconColor.withOpacity(0.06),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconContainer(
                  icon: icon,
                  color: iconColor,
                  iconSize: iconSize,
                  padding: iconContainerPadding,
                ),
                SizedBox(height: gapSize),
                _CardLabel(label: label, fontSize: labelFontSize),
                SizedBox(height: 4),
                _CardSubtitle(subtitle: subtitle, fontSize: subtitleFontSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Icon Container
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double iconSize;
  final double padding;

  const _IconContainer({
    required this.icon,
    required this.color,
    this.iconSize = 32,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

// Card Label
class _CardLabel extends StatelessWidget {
  final String label;
  final double fontSize;

  const _CardLabel({required this.label, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Card Subtitle
class _CardSubtitle extends StatelessWidget {
  final String subtitle;
  final double fontSize;

  const _CardSubtitle({required this.subtitle, this.fontSize = 11.5});

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, color: const Color(0xFF6B7280)),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Theme extensions
extension ThemeColors on Color {
  static const Color primary = Color(0xFF6366F1);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}
