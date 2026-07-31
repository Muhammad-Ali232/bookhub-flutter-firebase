import 'package:bookstore/Admin/AuthorCrud/editAuthor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorDetailPage extends StatefulWidget {
  final DocumentSnapshot document;

  const AuthorDetailPage({super.key, required this.document});

  @override
  State<AuthorDetailPage> createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailPage> {
  final CollectionReference _AuthorCollection = FirebaseFirestore.instance
      .collection('Authors');

  // --- DELETE Function ---
  Future<void> _deleteAuthor(BuildContext context) async {
    final AuthorName =
        (widget.document.data()! as Map<String, dynamic>)['Author Name'] ??
        'this Author';

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Author"),
            content: Text(
              "Are you sure you want to delete '$AuthorName'? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _AuthorCollection.doc(widget.document.id).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Author "$AuthorName" deleted successfully.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete Author.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data()! as Map<String, dynamic>;

    final titleName = data['Author Name'] ?? 'Untitled Author';
    final bookCount = data['bookCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Image Placeholder
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepPurple.shade200,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.title,
                    size: 60,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Title Name
              Text(
                titleName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),

              // Book Count
              Text(
                '$bookCount Books available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const Divider(height: 30, thickness: 1),

              const SizedBox(height: 50),

              // Edit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditAuthorPage(document: widget.document),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    "Edit Author",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                child: OutlinedButton.icon(
                  onPressed: () => _deleteAuthor(context),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    "Delete Author",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
