import 'dart:convert';

import 'package:bookstore/Admin/adminProfile.dart';
import 'package:bookstore/Admin/adminorders.dart';
import 'package:bookstore/Admin/authorPage.dart';
import 'package:bookstore/Admin/booksPage.dart';
import 'package:bookstore/Admin/feedback.dart';
import 'package:bookstore/Admin/genresPage.dart';
import 'package:bookstore/Admin/titlesPage.dart';
import 'package:bookstore/Users/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.book, color: Colors.deepPurple),
            ),
            const Text("BookStore",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white)),
            Row(
              children: [
                IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminProfilePage()),
    );
  },
  icon: const Icon(Icons.person, color: Colors.white),
),
                IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()));
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                )
              ],
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "Welcome to Admin Panel",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
              ),
            ),

            // ================= CARDS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _cardButton(Icons.book, "Add Book", Colors.deepPurple, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BooksPage()),
                  );
                }),
                _cardButton(Icons.library_books, "Add Genre", Colors.amber, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GenresPage()),
                  );
                }),
                _cardButton(Icons.person, "Add Author", Colors.green, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthorPage()),
                  );
                })
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _cardButton(Icons.category, "Add Title", Colors.pink, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TitlesPage()),
                  );
                }),
                _cardButton(Icons.shopping_cart, "Orders", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminOrdersPage()),
                  );
                }),
                _cardButton(Icons.feedback, "FeedBacks", Colors.teal, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminFeedbackPage()),
                  );
                }),
              ],
            ),

            const SizedBox(height: 40),

            // ================= NEW ORDERS SECTION =================
          const Text(
  "New Orders",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple,
  ),
),
const SizedBox(height: 10),

StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection("orders")
      .where("status", isEqualTo: "Pending")
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = snapshot.data!.docs;

    if (orders.isEmpty) {
      return const Text("No new orders found.");
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: orders.map((order) {
          final data = order.data();

          final items = data["items"] ?? [];
          final firstItem = items.isNotEmpty ? items[0] : null;

          final bookName = firstItem != null ? firstItem["title"] : "No Book";
          final bookImage = firstItem != null ? firstItem["image"] : null;

          return ListTile(
            leading: bookImage != null
                ? Image.memory(
                    base64Decode(bookImage),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.book, size: 40),

            title: Text(bookName),

            subtitle: Text("User: ${data['name'] ?? 'Unknown'}"),

            trailing: Text(
              data['status'] ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

            // 👇 CLICKABLE: Navigate to AdminOrdersPage
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminOrdersPage(),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  },
),

            const SizedBox(height: 40),

            // --------------------------------------------------------
            //                🔥 USERS SECTION
            // --------------------------------------------------------
            const Text(
              "Users",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),

           StreamBuilder(
  stream: FirebaseFirestore.instance.collection("users").snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = snapshot.data!.docs;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: users.map((user) {
          final data = user.data();
          final profileImage = data['profileImage'];

          return ListTile(
            leading: profileImage != null && profileImage.isNotEmpty
                ? Image.memory(
                    base64Decode(profileImage),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.person, size: 40),

            title: Text(data['name'] ?? "No Name"),
            subtitle: Text(data['email'] ?? "No Email"),
          );
        }).toList(),
      ),
    );
  },
),

          ],
        ),
      ),
    );
  }

  Widget _cardButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(vertical: 20),
        fixedSize: const Size(100, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
