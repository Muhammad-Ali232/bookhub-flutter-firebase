import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAuthorPage extends StatefulWidget {
  final DocumentSnapshot document;

  const EditAuthorPage({super.key, required this.document});

  @override
  State<EditAuthorPage> createState() => _EditAuthorPageState();
}

class _EditAuthorPageState extends State<EditAuthorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _AuthorController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;

  // firestore main titles collection
  final CollectionReference _AuthorCollection =
      FirebaseFirestore.instance.collection('Authors');

  @override
  void initState() {
    super.initState();

    final data = widget.document.data()! as Map<String, dynamic>;

    _AuthorController = TextEditingController(text: data['Author Name'] ?? '');
  }

  // --- UPDATE FUNCTION ---
  Future<void> _updateAuthor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _AuthorCollection.doc(widget.document.id).update({
          'Author Name': _AuthorController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showStatusDialog("Updated!", "Author updated successfully.");
      } catch (e) {
        print("Error updating Author: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update Author.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Status dialog
  void _showStatusDialog(String Author, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(Author, style: const TextStyle(color: Colors.deepPurple)),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);

              // yahan tum apna titles list page lagao
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _AuthorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Author", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Author Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(height: 30, color: Colors.deepPurple),

              // Title Input
              TextFormField(
                controller: _AuthorController,
                decoration: InputDecoration(
                  labelText: 'Author Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a Author name' : null,
              ),
              const SizedBox(height: 20),


              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateAuthor,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.update, color: Colors.white),
                  label: Text(
                    _isLoading ? "Updating..." : "Update Author",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
