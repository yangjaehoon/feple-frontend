// import 'package:flutter/material.dart';
// //import 'package:firebase_auth/firebase_auth.dart';
// //import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Messages extends StatelessWidget {
//   final String chattingroomname;
//   const Messages({super.key, required this.chattingroomname});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection(chattingroomname)
//           .orderBy('time', descending: true)
//           .snapshots(),
//       builder: (context,
//           AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//         final chatDocs = snapshot.data!.docs;
//
//         return ListView.builder(
//           shrinkWrap: true,
//           reverse: true,
//           itemCount: chatDocs.length,
//           itemBuilder: (context, index) {
//             if (chatDocs[index]['userId'] ==
//                 FirebaseAuth.instance.currentUser?.uid) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: Align(
//                   alignment: Alignment.topRight,
//                   child: Container(
//                     color: Colors.yellow,
//                     child: Padding(
//                       padding: const EdgeInsets.only(
//                           top: 5, bottom: 5, left: 10, right: 10),
//                       child: FittedBox(
//                         fit: BoxFit.contain,
//                         child: Align(
//                           alignment: Alignment.center,
//                           child: Text(
//                             chatDocs[index]['text'],
//                             style: const TextStyle(
//                                 fontSize: 15, color: Colors.black),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             } else {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: Align(
//                   alignment: Alignment.topLeft,
//                   child: Container(
//                     color: Colors.yellow,
//                     child: Padding(
//                       padding: const EdgeInsets.only(
//                           top: 5, bottom: 5, left: 10, right: 10),
//                       child: FittedBox(
//                         fit: BoxFit.contain,
//                         child: Align(
//                           alignment: Alignment.center,
//                           child: Text(
//                             chatDocs[index]['text'],
//                             style: const TextStyle(
//                                 fontSize: 15, color: Colors.black),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }
//           },
//         );
//       },
//     );
//   }
// }
