import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditBookPage extends StatefulWidget {
  final QueryDocumentSnapshot bookData;

  const EditBookPage({super.key, required this.bookData});

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String? selectedAuthor;
  String? selectedGenre;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  final CollectionReference booksCollection =
      FirebaseFirestore.instance.collection('books');

  @override
  void initState() {
    super.initState();
    final data = widget.bookData.data()! as Map<String, dynamic>;
    _titleController = TextEditingController(text: data["title"]);
    _priceController = TextEditingController(text: data["price"].toString());
    _descriptionController = TextEditingController(text: data["description"]);
    selectedAuthor = data["author"];
    selectedGenre = data["genre"];
  }

  Future<List<String>> _getAuthors() async {
    final snapshot = await FirebaseFirestore.instance.collection('Authors').get();
    return snapshot.docs.map((doc) => doc['Author Name'] as String).toList();
  }

  Future<List<String>> _getGenres() async {
    final snapshot = await FirebaseFirestore.instance.collection('genres').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String imageBase64;

        if (_selectedImage != null) {
          final bytes = await _selectedImage!.readAsBytes();
          imageBase64 = base64Encode(bytes);
        } else {
          imageBase64 = widget.bookData["coverImage"];
        }

        await booksCollection.doc(widget.bookData.id).update({
          "title": _titleController.text.trim(),
          "author": selectedAuthor,
          "genre": selectedGenre,
          "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
          "description": _descriptionController.text.trim(),
          "coverImage": imageBase64,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        _showStatusDialog("Updated!", "Book updated successfully.");
      } catch (e) {
        setState(() => _isLoading = false);
        print("Error updating book: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to update book.")));
      }
    }
  }

  void _showStatusDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.deepPurple)),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(context);
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
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List imageBytes = _selectedImage != null
        ? _selectedImage!.readAsBytesSync()
        : base64Decode(widget.bookData["coverImage"]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Book", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Book Image
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: MemoryImage(imageBytes),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Book Title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? "Enter book title" : null,
              ),
              const SizedBox(height: 15),

              // Author Dropdown
              FutureBuilder<List<String>>(
                future: _getAuthors(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    initialValue: selectedAuthor,
                    decoration: InputDecoration(
                      labelText: "Author",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: snapshot.data!
                        .map((author) => DropdownMenuItem(
                              value: author,
                              child: Text(author),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAuthor = value!;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Select an author" : null,
                  );
                },
              ),
              const SizedBox(height: 15),

              // Genre Dropdown
              FutureBuilder<List<String>>(
                future: _getGenres(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    initialValue: selectedGenre,
                    decoration: InputDecoration(
                      labelText: "Genre",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: snapshot.data!
                        .map((genre) => DropdownMenuItem(
                              value: genre,
                              child: Text(genre),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGenre = value!;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Select a genre" : null,
                  );
                },
              ),
              const SizedBox(height: 15),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 15),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateBook,
                  icon: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.update, color: Colors.white),
                  label: Text(
                    _isLoading ? "Updating..." : "Update Book",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
