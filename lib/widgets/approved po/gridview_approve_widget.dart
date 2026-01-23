import 'package:flutter/material.dart';

class GridViewApproveWidget<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double fixedHeight;

  // ✅ ADD THESE
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const GridViewApproveWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.fixedHeight,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double screenWidth = constraints.maxWidth;

        if (screenWidth >= 1200) {
          crossAxisCount = 4;
        } else if (screenWidth >= 800) {
          crossAxisCount = 3;
        } else if (screenWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        double itemWidth =
            (screenWidth - (crossAxisCount - 1) * 16.0) / crossAxisCount;
        double aspectRatio = itemWidth / fixedHeight;

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),

          // ✅ IMPORTANT FIX
          shrinkWrap: shrinkWrap,
          physics: physics,

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: aspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: fixedHeight,
              child: itemBuilder(context, index),
            );
          },
        );
      },
    );
  }
}
