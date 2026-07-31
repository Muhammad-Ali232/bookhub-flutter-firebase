import 'dart:convert';
import 'dart:typed_data';
import 'package:bookstore/Admin/BookCrud/updateBook.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot bookData;

  const BookDetailPage({super.key, required this.bookData});

  @override
  Widget build(BuildContext context) {
    Uint8List imageBytes = base64Decode(bookData["coverImage"]);

    String title = bookData["title"];
    String author = bookData["author"];
    String genre = bookData["genre"];
    String description = bookData["description"]; // direct fetch

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Book Detail", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Circular Image
            CircleAvatar(
              radius: 80,
              backgroundImage: MemoryImage(imageBytes),
              backgroundColor: Colors.grey[200],
            ),

            const SizedBox(height: 30),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 10),

            // Author
            Text(
              "Author: $author",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),

            const SizedBox(height: 10),

            // Genre
            Text(
              "Genre: $genre",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, color: Colors.teal, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 25),

            // Description
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditBookPage(bookData: bookData),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Update Book", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("books")
                      .doc(bookData.id)
                      .delete();

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text("Delete Book", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
