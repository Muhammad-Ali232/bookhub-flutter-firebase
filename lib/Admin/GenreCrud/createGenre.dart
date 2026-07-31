import 'package:flutter/material.dart';
// Firestore ko use karne ke liye is package ko uncomment karein aur pubspec.yaml mein add karein
import 'package:cloud_firestore/cloud_firestore.dart'; 

class CreateGenrePage extends StatefulWidget {
  const CreateGenrePage({super.key});

  @override
  State<CreateGenrePage> createState() => _CreateGenrePageState();
}

class _CreateGenrePageState extends State<CreateGenrePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  // Firebase Firestore Collection reference ko define karein
  // Iska naam 'genres' rakha gaya hai, jaisa ki aapki app ke liye sahi hai
  final CollectionReference _genresCollection = 
      FirebaseFirestore.instance.collection('genres');

  // --- Actual Firestore Save Function ---
  Future<void> _saveGenre() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // User se input kiye gaye data ko lein
      String genreName = _nameController.text.trim();
      String genreDescription = _descriptionController.text.trim();

      try {
        // Firestore mein naya document (genre) add karein
        await _genresCollection.add({
          // Keys ko simple rakha gaya hai: 'name' aur 'description'
          'name': genreName,
          'description': genreDescription,
          'bookCount': 0, // Shuru mein books ki tadad 0 hogi
          'createdAt': FieldValue.serverTimestamp(), // Date/Time record karne ke liye
        });

        // Data successfully save hone par loading band karein aur dialog dikhayein
        setState(() {
          _isLoading = false;
        });
        
        _showSuccessDialog();

      } catch (e) {
        // Agar koi error aata hai to console mein print karein
        print("Error saving genre to Firestore: $e");
        
        setState(() {
          _isLoading = false;
        });

        // Error message show karein (Optional: ek Snackbar ya Alert Dialog use kar sakte hain)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save genre. Please try again.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User ko dialog band karne se rokein jab tak OK na dabaye
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success!", style: TextStyle(color: Colors.deepPurple)),
          content: Text("Genre '${_nameController.text}' saved successfully!"),
          actions: <Widget>[
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Pehle dialog band karein, phir GenresPage par wapas jayein
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
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
        title: const Text("Create New Genre",
            style: TextStyle(color: Colors.white)),
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
                "Genre Details",
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
                  hintText: 'e.g., Science Fiction',
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
                  hintText: 'A brief description of this genre...',
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

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveGenre,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ))
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isLoading ? "Saving..." : "Save New Genre",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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