import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class POSkeletonList extends StatelessWidget {
  const POSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const _POSkeletonCard();
      },
    );
  }
}

class _POSkeletonCard extends StatelessWidget {
  const _POSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 110, // 🔥 full card height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14), // 🔥 rounded card
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP ROW (Title + Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 14, width: 140, color: Colors.grey),

                  Container(
                    height: 20,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// SECOND LINE
              Container(height: 12, width: double.infinity, color: Colors.grey),

              const SizedBox(height: 10),

              /// THIRD LINE
              Container(height: 12, width: 200, color: Colors.grey),

              const Spacer(),

              /// BOTTOM ROW (small details)
              Row(
                children: [
                  Container(height: 10, width: 80, color: Colors.grey),
                  const SizedBox(width: 12),
                  Container(height: 10, width: 60, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
