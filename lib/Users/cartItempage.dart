import 'dart:convert' show base64Decode;
import 'package:bookstore/Users/checkout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'CheckoutSummaryPage.dart';   // <-- Add this import

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.white)),
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

          var docs = snapshot.data!.docs;

          docs.sort((a, b) {
            var t1 = a['createdAt'] == null
                ? 0
                : a['createdAt'].millisecondsSinceEpoch;

            var t2 = b['createdAt'] == null
                ? 0
                : b['createdAt'].millisecondsSinceEpoch;

            return t2.compareTo(t1);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Your cart is empty 😢",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

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
                    int qty = item['qty'] ?? 1;
                    double price = item['price'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: item['coverImage'] != null
                            ? Image.memory(
                                base64Decode(item['coverImage']),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book, size: 50),

                        title: Text(item['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['author'] ?? ''),
                            const SizedBox(height: 5),
                            Text(
                              "₨$price x $qty",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        trailing: SizedBox(
                          width: 90,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (qty > 1) {
                                    FirebaseFirestore.instance
                                        .collection('cart')
                                        .doc(item.id)
                                        .update({'qty': qty - 1});
                                  } else {
                                    FirebaseFirestore.instance
                                        .collection('cart')
                                        .doc(item.id)
                                        .delete();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.remove,
                                      color: Colors.white, size: 18),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                "$qty",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(width: 8),

                              GestureDetector(
                                onTap: () {
                                  FirebaseFirestore.instance
                                      .collection('cart')
                                      .doc(item.id)
                                      .update({'qty': qty + 1});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 15),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: ₨${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    // -------- Updated Button --------
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutSummaryPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: const Text(
                        "Proceed to Checkout",
                        style: TextStyle(color: Colors.white),
                      ),
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
}
