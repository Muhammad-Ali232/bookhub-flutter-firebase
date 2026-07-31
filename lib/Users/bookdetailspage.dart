import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String id;

  const BookDetailPage({super.key, required this.data, required this.id});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {

  // ---------------- ADD REVIEW FUNCTION ----------------
  Future<void> addReview(double rating, String reviewText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      "userId": user.uid,
      "bookId": widget.id,
      "rating": rating.toDouble(),   // ⭐ FIX
      "review": reviewText,
      "createdAt": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review added successfully!")),
    );
  }

  // ---------------- LIKE REVIEW FUNCTION ----------------
 // ---------------- LIKE REVIEW FUNCTION (Updated) ----------------
Future<void> likeReview(String reviewId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final likeRef = FirebaseFirestore.instance
      .collection("reviewLikes")
      .doc("${reviewId}_${user.uid}");

  final doc = await likeRef.get();

  final reviewRef = FirebaseFirestore.instance.collection("reviews").doc(reviewId);

  if (doc.exists) {
    await likeRef.delete(); // Unlike
    await reviewRef.update({
      "likesCount": FieldValue.increment(-1), // likes count ko reduce karo
    });
  } else {
    await likeRef.set({
      "userId": user.uid,
      "reviewId": reviewId,
      "createdAt": DateTime.now(),
    });
    await reviewRef.update({
      "likesCount": FieldValue.increment(1), // likes count ko increase karo
    });
  }
}


  // ---------------- ADD TO CART ----------------
  Future<void> addToCart() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cart').add({
        "userId": currentUser.uid,
        "bookId": widget.id,
        "title": widget.data['title'],
        "author": widget.data['author'],
        "price": widget.data['price'],
        "coverImage": widget.data['coverImage'],
        "qty": 1,
        "createdAt": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Book Added to Cart!")),
      );
    } catch (e) {
      print(e);
    }
  }

  // ---------------- ADD TO WISHLIST ----------------
  Future<void> addToWishlist() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('wishlist').add({
      "userId": currentUser.uid,
      "bookId": widget.id,
      "title": widget.data['title'],
      "author": widget.data['author'],
      "coverImage": widget.data['coverImage'],
      "createdAt": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to Wishlist")),
    );
  }

  // ---------------- REVIEW DIALOG ----------------
  void showReviewDialog() {
    double userRating = 3;
    TextEditingController reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Write a Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ⭐⭐⭐⭐⭐ STAR RATING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= userRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            userRating = starIndex.toDouble();
                          });
                        },
                      );
                    }),
                  ),

                  Text(
                    "${userRating.toStringAsFixed(1)} ⭐",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: reviewCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(hintText: "Write your review..."),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    await addReview(userRating, reviewCtrl.text);
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- AVERAGE RATING WIDGET ----------------
  Widget buildAverageRating() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('bookId', isEqualTo: widget.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No Ratings Yet");
        }

        final reviews = snapshot.data!.docs;

        double avg = reviews
            .map((d) => (d['rating'] as num).toDouble())  // ⭐ FIX
            .reduce((a, b) => a + b) /
            reviews.length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${avg.toStringAsFixed(1)} ⭐",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 5),
            Text("(${reviews.length} reviews)")
          ],
        );
      },
    );
  }

  // ---------------- REVIEW LIST WIDGET ----------------
  // ---------------- REVIEW LIST WIDGET (Updated) ----------------
Widget buildReviews() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection("reviews")
        .where("bookId", isEqualTo: widget.id)
        // .orderBy("createdAt", descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Text("No reviews yet");
      }

      final reviews = snapshot.data!.docs;

      return Column(
        children: reviews.map((doc) {
          final reviewId = doc.id;
          // final likes = doc['likesCount'] ?? 0; // ab likes directly review doc se

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              title: Text("${(doc['rating'] as num).toDouble()} ⭐"),
              subtitle: Text(doc['review']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up, size: 22),
                        const SizedBox(width: 5),
                        // Text("$likes"),
                      ],
                    ),
                    onPressed: () => likeReview(reviewId),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Book Detail", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: showReviewDialog,
        child: const Icon(Icons.rate_review, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Book Cover
Container(
  height: 200, // Book height
  width: 140,  // Book width
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: Colors.grey.shade200,
    image: (data['coverImage'] != null && data['coverImage'].isNotEmpty)
        ? DecorationImage(
            image: MemoryImage(base64Decode(data['coverImage'])),
            fit: BoxFit.cover,
          )
        : null,
  ),
  child: (data['coverImage'] == null || data['coverImage'].isEmpty)
      ? const Center(
          child: Icon(Icons.book, size: 60, color: Colors.grey),
        )
      : null,
),
const SizedBox(height: 15),

            // Title
            Text(
              data['title'],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            // Author + Genre
            Text(
              "By ${data['author']} • ${data['genre']}",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 15),

            // Price
            Text(
              "PKR ${data['price']}",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              data['description'] ?? "No Description",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Add to Cart / Wishlist
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: addToCart,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple),
                    child: const Text("Add to Cart",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: addToWishlist,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink),
                    child: const Text("Wishlist",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            buildAverageRating(),
            const SizedBox(height: 20),

            const Text(
              "Reviews",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            buildReviews(),
          ],
        ),
      ),
    );
  }
}
