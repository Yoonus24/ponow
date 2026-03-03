import 'package:flutter/material.dart';

class GridViewWidget<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollPhysics? physics;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;

  const GridViewWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
  });

  @override
  State<GridViewWidget<T>> createState() => _GridViewWidgetState<T>();
}

class _GridViewWidgetState<T> extends State<GridViewWidget<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

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
          controller: _scrollController,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1.0,
          ),
          itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == widget.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Loading more...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return widget.itemBuilder(context, index);
          },
        );
      },
    );
  }
}
