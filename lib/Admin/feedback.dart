import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  // Book info fetch karne ka helper
  Future<Map<String, dynamic>> getBookInfo(String bookId) async {
    final doc = await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .get();
    if (doc.exists && doc.data() != null) {
      return {
        "title": doc['title'] ?? "Unknown Book",
        "coverImage": doc['coverImage'], // base64 string
      };
    }
    return {"title": "Unknown Book", "coverImage": null};
  }

  // User name fetch helper
  Future<String> getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists && doc.data() != null) {
      return doc['name'] ?? "Unknown User";
    }
    return "Unknown User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Feedbacks",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!.docs;

          if (reviews.isEmpty) {
            return const Center(child: Text("No feedbacks yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final bookId = review['bookId'];
              final userId = review['userId'];
              final rating = review['rating'];
              final reviewText = review['review'];
              final createdAt = review['createdAt'].toDate();

              return FutureBuilder(
                future: Future.wait([getBookInfo(bookId), getUserName(userId)]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (!snapshot.hasData) {
                    return const Card(
                      child: ListTile(title: Text("Loading...")),
                    );
                  }

                  final bookInfo = snapshot.data![0] as Map<String, dynamic>;
                  final userName = snapshot.data![1] as String;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: bookInfo['coverImage'] != null
                          ? CircleAvatar(
                              radius: 25,
                              backgroundImage: MemoryImage(
                                base64Decode(bookInfo['coverImage']),
                              ),
                            )
                          : const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.book),
                            ),
                      title: Text(
                        "$rating ⭐ • ${bookInfo['title']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(reviewText ?? "No text"),
                          const SizedBox(height: 5),
                          Text(
                            "By: $userName",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "At: $createdAt",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
