import 'dart:convert';
import 'package:bookstore/Users/orderForm.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutSummaryPage extends StatelessWidget {
  const CheckoutSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Summary", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart')
            .where('userId', isEqualTo: userId)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Your cart is empty 😢"));
          }

          // -------- Total Calculation --------
          double total = 0;
          for (var doc in docs) {
            total += (doc['price'] ?? 0) * (doc['qty'] ?? 1);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index];

                    return ListTile(
                      leading: item['coverImage'] != null
                          ? Image.memory(
                              base64Decode(item['coverImage']),
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.book, size: 50),

                      title: Text(item['title'] ?? ''),
                      subtitle: Text("Qty: ${item['qty']}"),

                      trailing: Text(
                        "₨${(item['price'] * item['qty']).toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                ),
              ),

              // -------- Total + Confirm Order --------
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: Colors.grey.shade200,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "₨${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // -------- Confirm Button --------
                    SizedBox(
                      width: double.infinity,
                      child:ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderFormPage(),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
  ),
  child: const Text(
    "Confirm Order",
    style: TextStyle(color: Colors.white),
  ),
)

                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

//   Future<void> _confirmOrder(
//       BuildContext context, List<QueryDocumentSnapshot> items, double total, String userId) async {
    
//     final ordersRef = FirebaseFirestore.instance.collection('orders').doc();

//     // 🔥 Add order record
//     await ordersRef.set({
//       'orderId': ordersRef.id,
//       'userId': userId,
//       'total': total,
//       'createdAt': DateTime.now(),
//     });

//     // 🔥 Add all order items
//     for (var item in items) {
//       await ordersRef.collection('items').add({
//         'title': item['title'],
//         'price': item['price'],
//         'qty': item['qty'],
//         'coverImage': item['coverImage'],
//       });
//     }

//     // 🔥 Clear cart
//     for (var item in items) {
//       await item.reference.delete();
//     }

//     // 🔥 Show confirmation dialog
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Order Placed!"),
//         content: const Text("Your order has been successfully placed."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
}
