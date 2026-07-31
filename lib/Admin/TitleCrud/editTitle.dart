import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTitlePage extends StatefulWidget {
  final DocumentSnapshot document;

  const EditTitlePage({super.key, required this.document});

  @override
  State<EditTitlePage> createState() => _EditTitlePageState();
}

class _EditTitlePageState extends State<EditTitlePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;

  // firestore main titles collection
  final CollectionReference _titlesCollection =
      FirebaseFirestore.instance.collection('titles');

  @override
  void initState() {
    super.initState();

    final data = widget.document.data()! as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['Title Name'] ?? '');
  }

  // --- UPDATE FUNCTION ---
  Future<void> _updateTitle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _titlesCollection.doc(widget.document.id).update({
          'Title Name': _titleController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showStatusDialog("Updated!", "Title updated successfully.");
      } catch (e) {
        print("Error updating title: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update title.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Status dialog
  void _showStatusDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.deepPurple)),
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Title", style: TextStyle(color: Colors.white)),
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
                "Edit Title Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(height: 30, color: Colors.deepPurple),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a title name' : null,
              ),
              const SizedBox(height: 20),


              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateTitle,
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
                    _isLoading ? "Updating..." : "Update Title",
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
