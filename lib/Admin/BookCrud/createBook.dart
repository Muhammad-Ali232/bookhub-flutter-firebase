import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CreateBookPage extends StatefulWidget {
  const CreateBookPage({super.key});

  @override
  State<CreateBookPage> createState() => _CreateBookPageState();
}

class _CreateBookPageState extends State<CreateBookPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? selectedTitle;
  String? selectedAuthor;
  String? selectedGenre;
  bool _isLoading = false;

  Uint8List? _selectedImageBytes; // 👈 Updated
  final ImagePicker _picker = ImagePicker();

  // Firestore Collections
  final CollectionReference booksCollection =
      FirebaseFirestore.instance.collection('books');

  // Fetch Titles
  Future<List<String>> _getTitles() async {
    final snapshot = await FirebaseFirestore.instance.collection('titles').get();
    return snapshot.docs.map((doc) => doc['Title Name'] as String).toList();
  }

  // Fetch Authors
  Future<List<String>> _getAuthors() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Authors').get();
    return snapshot.docs.map((doc) => doc['Author Name'] as String).toList();
  }

  // Fetch Genres
  Future<List<String>> _getGenres() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('genres').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  // Pick Image & Convert to Bytes
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  // Save Book with Base64 Image
  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a book cover image")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String base64Image = base64Encode(_selectedImageBytes!);

        await booksCollection.add({
          'title': selectedTitle,
          'author': selectedAuthor,
          'genre': selectedGenre,
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'coverImage': base64Image,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);
        _showSuccessDialog();
      } catch (e) {
        setState(() => _isLoading = false);
        print("Error: $e");
      }
    }
  }

  // Success Popup
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Book added successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Create New Book", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const Text("Book Details",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),

            const Divider(height: 30, color: Colors.deepPurple),

// ---------------- Dynamic Title Dropdown ----------------
FutureBuilder<List<String>>(
  future: _getTitles(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Book Title",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ✅ Adjust spacing
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
      isExpanded: true, // ✅ Important for proper width & spacing
      initialValue: selectedTitle,
      items: snapshot.data!
          .map((title) => DropdownMenuItem(
                value: title,
                child: Text(title),
              ))
          .toList(),
      onChanged: (value) => setState(() => selectedTitle = value),
      validator: (value) =>
          value == null ? "Please select a book title" : null,
    );
  },
),

            const SizedBox(height: 20),

            // ---------------- Author Dropdown ----------------
            FutureBuilder<List<String>>(
              future: _getAuthors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return DropdownButtonFormField(
                  decoration: InputDecoration(
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    labelText: "Author",
                    prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  items: snapshot.data!
                      .map((author) =>
                          DropdownMenuItem(value: author, child: Text(author)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedAuthor = value),
                  validator: (value) =>
                      value == null ? "Please select an author" : null,
                );
              },
            ),

            const SizedBox(height: 20),

            // ---------------- Genre Dropdown ----------------
            FutureBuilder<List<String>>(
              future: _getGenres(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return DropdownButtonFormField(
                  decoration: InputDecoration(
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    labelText: "Genre",
                    prefixIcon: const Icon(Icons.category, color: Colors.deepPurple),
                  ),
                  items: snapshot.data!
                      .map((genre) =>
                          DropdownMenuItem(value: genre, child: Text(genre)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedGenre = value),
                  validator: (value) =>
                      value == null ? "Please select a genre" : null,
                );
              },
            ),

            const SizedBox(height: 25),

            // ---------------- Image Picker ----------------
            const Text("Book Cover Image",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                  color: Colors.deepPurple.withOpacity(0.1),
                ),
                child: _selectedImageBytes == null
                    ? const Center(
                        child: Text(
                          "Tap to Choose Image",
                          style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // ---------------- Price ----------------
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon:
                    const Icon(Icons.currency_rupee, color: Colors.deepPurple),
              ),
              validator: (value) => value!.isEmpty ? "Enter price" : null,
            ),

            const SizedBox(height: 30),

            // ---------------- Description ----------------
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 40),

            // ---------------- Save Button ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveBook,
                icon: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(_isLoading ? "Saving..." : "Save Book",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
