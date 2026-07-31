import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final List<String> statuses = [
    "Pending",
    "In Progress",
    "Shipped",
    "In Shipment",
    "Delivered",
    "Cancelled"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No Orders Found", style: TextStyle(fontSize: 18)),
            );
          }

          // Sort by createdAt DESC
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

              final orderId = data['orderId'] ?? order.id;
              final status = data['status'] ?? 'Pending';
              final total = (data['total'] ?? 0).toDouble();
              final items = data['items'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ExpansionTile(
                  leading: const Icon(Icons.shopping_cart,
                      color: Colors.deepPurple),
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

                      // 🔥 STATUS DROPDOWN FOR ADMIN
                     DropdownButton<String>(
  value: status,
  underline: const SizedBox(),
  items: statuses.map((s) {
    return DropdownMenuItem(
      value: s,
      child: Text(s),
    );
  }).toList(),
  onChanged: (status == 'Cancelled') 
      ? null // disable dropdown if cancelled
      : (value) {
          FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .update({"status": value});
        },
),

                    ],
                  ),

                  subtitle: Text(
                    "Total: ₨${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),

                 children: [
  // ---------------- USER INFO ----------------
  Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Customer Info",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple)),

        const SizedBox(height: 8),

        Text("Order ID: ${data['orderId'] ?? 'N/A'}"),
        Text("Name: ${data['name'] ?? 'N/A'}"),
        Text("Phone: ${data['phone'] ?? 'N/A'}"),
        Text("Address: ${data['address'] ?? 'N/A'}"),
      ],
    ),
  ),

  const Divider(),

  // ---------------- ORDER ITEMS ----------------
  Column(
    children: items.map((item) {
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
          "Qty: ${itm['qty']} | ₨${itm['price']?.toStringAsFixed(2) ?? "0"}",
        ),
      );
    }).toList(),
  ),

  // ---------------- CANCEL REASON ----------------
  if (status == 'Cancelled' && (data['cancelReason'] ?? '').isNotEmpty)
    Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        "Cancel Reason: ${data['cancelReason']}",
        style: const TextStyle(
            color: Colors.red, fontWeight: FontWeight.bold),
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
}
