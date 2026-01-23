import 'package:flutter/material.dart';

class GridViewWidget<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollPhysics? physics;

  const GridViewWidget({
    super.key,
    required this.items,
    required this.itemBuilder, this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of items per row based on the screen width
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4; // Extra-large screens
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 3; // Large screens (tablets)
        } else if (constraints.maxWidth >= 480) {
          crossAxisCount = 2; // Medium screens
        } else {
          crossAxisCount = 1; // Small screens (mobile)
        }

        return GridView.builder(
          padding: EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: items.length,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
