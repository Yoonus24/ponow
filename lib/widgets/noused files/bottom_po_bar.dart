// import 'package:flutter/material.dart';
// import '../models/po.dart';
// import 'po page/po_card.dart';

// class BottomPOBar extends StatelessWidget {
//   final List<PO> visiblePOs;
//   final VoidCallback? onStatusChanged;

//   const BottomPOBar({
//     super.key,
//     required this.visiblePOs,
//     this.onStatusChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.grey[200],
//       height: 60.0,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: visiblePOs.length,
//         itemBuilder: (context, index) {
//           return POCard(
//             po: visiblePOs[index],
//             // Remove onStatusChanged parameter since POCard doesn't have it
//           );
//         },
//       ),
//     );
//   }
// }
