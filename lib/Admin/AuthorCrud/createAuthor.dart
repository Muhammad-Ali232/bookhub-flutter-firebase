import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAuthorPage extends StatefulWidget {
  const AddAuthorPage({super.key});

  @override
  State<AddAuthorPage> createState() => _AddAuthorPageState();
}

class _AddAuthorPageState extends State<AddAuthorPage> {
  final TextEditingController AuthorController = TextEditingController();

  final CollectionReference Author =
      FirebaseFirestore.instance.collection('Authors');

  Future<void> addAuthor() async {
    String AName = AuthorController.text.trim();

    await Author.add({
      'Author Name': AName,
    });

    _showStatusDialog("Success", "Author Added Successfully!");
  }

  void _showStatusDialog(String Author, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(Author, style: const TextStyle(color: Colors.deepPurple)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "OK",
              style: TextStyle(
                  color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Author", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
        // ← Arrow back icon color
  iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: AuthorController,
              decoration: const InputDecoration(
                labelText: "Enter Author",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: addAuthor,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
              ),
              child: const Text(
                "Add Author",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
