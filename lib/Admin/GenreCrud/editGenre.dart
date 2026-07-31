import 'package:bookstore/Admin/genresPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditGenrePage extends StatefulWidget {
  // DocumentSnapshot ko constructor mein receive karein, jismein current genre ka data aur ID hai.
  final DocumentSnapshot document;

  const EditGenrePage({super.key, required this.document});

  @override
  State<EditGenrePage> createState() => _EditGenrePageState();
}

class _EditGenrePageState extends State<EditGenrePage> {
  final _formKey = GlobalKey<FormState>();
  // Text input ke liye controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false; // Loading state manage karne ke liye

  // Firestore collection reference
  final CollectionReference _genresCollection = FirebaseFirestore.instance
      .collection('genres');

  @override
  void initState() {
    super.initState();
    // Existing data se controllers ko initialize karein taki fields mein pehle se data bhara ho
    final data = widget.document.data()! as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name'] ?? '');
    _descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );
  }

  // --- UPDATE Function (CRUD - U) ---
  Future<void> _updateGenre() async {
    // Form validation check karein
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Loading shuru karein
      });

      String docId = widget.document.id; // Document ki ID nikalen

      try {
        // Firestore ke update() method ka use karein (Basic method)
        await _genresCollection.doc(docId).update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'updatedAt':
              FieldValue.serverTimestamp(), // Update time record karein
        });

        // Success hone par dialog dikhayein
        _showStatusDialog("Update Successful!", "Genre updated successfully.");
      } catch (e) {
        print("Error updating genre in Firestore: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update genre.')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Loading band karein
        });
      }
    }
  }

  // Status message dikhane ke liye helper function
  void _showStatusDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.deepPurple)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog close

                // 👉 Ab dialog band hote hi GenresPage par navigation
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GenresPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Genre", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                "Edit Genre Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(height: 30, color: Colors.deepPurple),

              // Genre Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Genre Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.label, color: Colors.deepPurple),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a genre name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Genre Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60, left: 0),
                    child: Icon(Icons.description, color: Colors.deepPurple),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateGenre,
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
                    _isLoading ? "Updating..." : "Update Genre",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
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
