import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "You have no orders yet 😢",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Safe sort by createdAt descending
          orders.sort((a, b) {
            final t1 = a['createdAt'] != null
                ? (a['createdAt'] as Timestamp).millisecondsSinceEpoch
                : 0;
            final t2 = b['createdAt'] != null
                ? (b['createdAt'] as Timestamp).millisecondsSinceEpoch
                : 0;
            return t2.compareTo(t1);
          });

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data()! as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>? ?? [];
              final status = data['status'] ?? 'In Progress';
              final orderId = data['orderId'] ?? order.id;
              final total = (data['total'] ?? 0).toDouble();
              final cancelReason = data['cancelReason'] ?? '';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ExpansionTile(
                  leading:
                      const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Order ID: $orderId",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          color: status == 'Delivered'
                              ? Colors.green
                              : status == 'Cancelled'
                                  ? Colors.red
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "Total: ₨${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    ...items.map((item) {
                      final itm = item as Map<String, dynamic>;
                      return ListTile(
                        leading: itm['image'] != null && itm['image'] != ''
                            ? Image.memory(
                                base64Decode(itm['image']),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book, size: 50),
                        title: Text(itm['title'] ?? ''),
                        subtitle: Text(
                            "Qty: ${itm['qty'] ?? 1} | ₨${itm['price']?.toStringAsFixed(2) ?? '0'}"),
                      );
                    }),

                    // Show cancel reason if order is cancelled
                    if (status == 'Cancelled')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Reason: $cancelReason",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Show Cancel Order button if order not delivered or cancelled
                    if (status != 'Delivered' && status != 'Cancelled')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () =>
                              _showCancelDialog(context, order.id),
                          child: const Text("Cancel Order",style: TextStyle(color: Colors.white),),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Order"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for cancellation:"),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: "Reason",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;

                // Update Firestore order
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({
                  'status': 'Cancelled',
                  'cancelReason': reason,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Order cancelled successfully")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
