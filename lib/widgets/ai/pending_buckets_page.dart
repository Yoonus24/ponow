// import 'package:flutter/material.dart';
// import 'package:purchaseorders2/services/ai/scan_bucket_model.dart';
// import 'package:purchaseorders2/services/ai/scan_bucket_service.dart';

// class PendingBucketsPage extends StatefulWidget {
//   const PendingBucketsPage({super.key});

//   @override
//   State<PendingBucketsPage> createState() => _PendingBucketsPageState();
// }

// class _PendingBucketsPageState extends State<PendingBucketsPage> {
//   final ScanBucketService service = ScanBucketService();
//   late Future<List<ScanBucket>> futureBuckets;

//   // Search related variables
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   List<ScanBucket> _allBuckets = [];
//   List<ScanBucket> _filteredBuckets = [];

//   @override
//   void initState() {
//     super.initState();
//     futureBuckets = service.getBuckets();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Filter buckets based on search query
//   void _filterBuckets(String query) {
//     setState(() {
//       _searchQuery = query;
//       if (query.isEmpty) {
//         _filteredBuckets = List.from(_allBuckets);
//       } else {
//         _filteredBuckets = _allBuckets.where((bucket) {
//           final searchLower = query.toLowerCase();
//           return bucket.bucketNo.toLowerCase().contains(searchLower) ||
//               bucket.vendorName.toLowerCase().contains(searchLower) ||
//               bucket.invoiceNumber.toLowerCase().contains(searchLower);
//         }).toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F4F8),
//       appBar: AppBar(
//         title: const Text(
//           "Pending Buckets",
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1A3A5F),
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             color: Color(0xFF2196F3),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: Colors.grey.shade200),
//         ),
//       ),
//       body: FutureBuilder<List<ScanBucket>>(
//         future: futureBuckets,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const _LoadingState();
//           }

//           if (snapshot.hasError) {
//             return _ErrorState(error: snapshot.error.toString());
//           }

//           final buckets = snapshot.data ?? [];

//           // Store all buckets and initialize filtered list
//           if (_allBuckets.isEmpty && buckets.isNotEmpty) {
//             _allBuckets = buckets;
//             _filteredBuckets = buckets;
//           }

//           if (buckets.isEmpty) {
//             return const _EmptyState();
//           }

//           return Column(
//             children: [
//               // Search Bar
//               _SearchBar(
//                 controller: _searchController,
//                 onChanged: _filterBuckets,
//                 onClear: () {
//                   _searchController.clear();
//                   _filterBuckets('');
//                 },
//               ),
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     setState(() {
//                       futureBuckets = service.getBuckets();
//                     });
//                     final refreshedBuckets = await futureBuckets;
//                     _allBuckets = refreshedBuckets;
//                     _filterBuckets(_searchQuery);
//                   },
//                   child: _filteredBuckets.isEmpty
//                       ? _EmptySearchState(searchQuery: _searchQuery)
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 12,
//                           ),
//                           itemCount: _filteredBuckets.length,
//                           itemBuilder: (context, index) {
//                             final bucket = _filteredBuckets[index];
//                             return _BucketCard(bucket: bucket);
//                           },
//                         ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// // Search Bar Widget
// class _SearchBar extends StatelessWidget {
//   final TextEditingController controller;
//   final Function(String) onChanged;
//   final VoidCallback onClear;

//   const _SearchBar({
//     required this.controller,
//     required this.onChanged,
//     required this.onClear,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: TextField(
//           controller: controller,
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             hintText: 'Search by bucket number, vendor, or invoice...',
//             hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
//             prefixIcon: const Icon(
//               Icons.search_rounded,
//               color: Color(0xFF2196F3),
//               size: 20,
//             ),
//             suffixIcon: controller.text.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(
//                       Icons.close_rounded,
//                       color: Color(0xFF9CA3AF),
//                       size: 20,
//                     ),
//                     onPressed: onClear,
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             fillColor: Colors.white,
//             filled: true,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Empty Search State Widget
// class _EmptySearchState extends StatelessWidget {
//   final String searchQuery;
//   const _EmptySearchState({required this.searchQuery});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 100,
//             height: 100,
//             decoration: BoxDecoration(
//               color: const Color(0xFF2196F3).withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.search_off_rounded,
//               size: 48,
//               color: Color(0xFF2196F3),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             "No results found",
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1A3A5F),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "No buckets matching \"$searchQuery\"",
//             style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           TextButton.icon(
//             onPressed: () {
//               // Clear search
//               final searchBar = context
//                   .findAncestorStateOfType<_PendingBucketsPageState>();
//               searchBar?._searchController.clear();
//               searchBar?._filterBuckets('');
//             },
//             icon: const Icon(Icons.clear_rounded, size: 18),
//             label: const Text("Clear Search"),
//             style: TextButton.styleFrom(
//               foregroundColor: const Color(0xFF2196F3),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Loading State Widget
// class _LoadingState extends StatelessWidget {
//   const _LoadingState();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: const Color(0xFF2196F3).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const CircularProgressIndicator(
//               strokeWidth: 3,
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             "Loading buckets...",
//             style: TextStyle(
//               fontSize: 16,
//               color: Color(0xFF6B7280),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Error State Widget
// class _ErrorState extends StatelessWidget {
//   final String error;
//   const _ErrorState({required this.error});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: const Color(0xFFEF4444).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.error_outline_rounded,
//               size: 48,
//               color: Color(0xFFEF4444),
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             "Failed to load buckets",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1A3A5F),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               error,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             icon: const Icon(Icons.refresh_rounded, size: 18),
//             label: const Text("Try Again"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF2196F3),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Empty State Widget
// class _EmptyState extends StatelessWidget {
//   const _EmptyState();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: const Color(0xFF2196F3).withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.folder_open_rounded,
//               size: 56,
//               color: Color(0xFF2196F3),
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             "No Buckets Found",
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1A3A5F),
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             "All caught up! No pending buckets to process.",
//             style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Enhanced Bucket Card Widget
// class _BucketCard extends StatelessWidget {
//   final ScanBucket bucket;
//   const _BucketCard({required this.bucket});

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return const Color(0xFFF59E0B);
//       case 'processing':
//         return const Color(0xFF2196F3);
//       case 'completed':
//         return const Color(0xFF10B981);
//       case 'failed':
//         return const Color(0xFFEF4444);
//       default:
//         return const Color(0xFF6B7280);
//     }
//   }

//   String _getBucketNumber(String bucketNo) {
//     return bucketNo.replaceAll("SB", "");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {
//             // Navigate to bucket details
//           },
//           borderRadius: BorderRadius.circular(20),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 12,
//                   spreadRadius: 1,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Leading Avatar with Bucket Number
//                       Container(
//                         width: 56,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               const Color(0xFF2196F3),
//                               const Color(0xFF64B5F6),
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF2196F3).withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Text(
//                             _getBucketNumber(bucket.bucketNo),
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       // Content
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     bucket.bucketNo,
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Color(0xFF1A3A5F),
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: _getStatusColor(
//                                       bucket.status,
//                                     ).withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Container(
//                                         width: 6,
//                                         height: 6,
//                                         decoration: BoxDecoration(
//                                           color: _getStatusColor(bucket.status),
//                                           shape: BoxShape.circle,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         bucket.status.toUpperCase(),
//                                         style: TextStyle(
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.w600,
//                                           color: _getStatusColor(bucket.status),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 8),
//                             // Vendor Name
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.business_rounded,
//                                   size: 14,
//                                   color: Color(0xFF6B7280),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Expanded(
//                                   child: Text(
//                                     bucket.vendorName,
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       color: Color(0xFF4B5563),
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 6),
//                             // Invoice Number
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.receipt_rounded,
//                                   size: 14,
//                                   color: Color(0xFF6B7280),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   "Invoice: ${bucket.invoiceNumber}",
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: Color(0xFF6B7280),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 8),
//                             // Action Buttons
//                             Row(
//                               children: [
//                                 _ActionChip(
//                                   icon: Icons.visibility_rounded,
//                                   label: "View Details",
//                                   onTap: () {},
//                                   color: const Color(0xFF2196F3),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 _ActionChip(
//                                   icon: Icons.play_arrow_rounded,
//                                   label: "Process",
//                                   onTap: () {},
//                                   color: const Color(0xFF10B981),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Action Chip Widget
// class _ActionChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//   final Color color;

//   const _ActionChip({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.2), width: 0.5),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 14, color: color),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
