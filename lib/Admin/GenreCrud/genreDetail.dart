import 'package:bookstore/Admin/GenreCrud/editGenre.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Edit page ko import karein

// 1. Convert to StatefulWidget
class GenreDetailPage extends StatefulWidget {
  final DocumentSnapshot document;

  const GenreDetailPage({super.key, required this.document});

  @override
  State<GenreDetailPage> createState() => _GenreDetailPageState();
}

class _GenreDetailPageState extends State<GenreDetailPage> {
  // Collection reference
  final CollectionReference _genresCollection =
      FirebaseFirestore.instance.collection('genres');

  // --- DELETE Function (CRUD - D) ---
  Future<void> _deleteGenre(BuildContext context) async {
    final genreName = (widget.document.data()! as Map<String, dynamic>)['name'] ?? 'this genre';

    // 1. Confirmation Dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '$genreName'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // 2. Delete the document
        // document.id se document reference lekar delete karein
        await _genresCollection.doc(widget.document.id).delete();

        // 3. Show SnackBar (jaisa ki image mein dikhaya gaya hai)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Genre "$genreName" deleted successfully.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red, // Delete ke liye red color
          ),
        );

        // Pop twice to go back to the GenresPage (Detail Page se list page par wapas aayenge)
        Navigator.of(context).pop();

      } catch (e) {
        print("Error deleting genre from Firestore: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete genre. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Document data extract karein
    final data = widget.document.data()! as Map<String, dynamic>;
    final genreName = data['name'] ?? 'Untitled Genre';
    final genreDescription = data['description'] ?? 'No description available.';
    // bookCount ko fetch karein
    final bookCount = data['bookCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(genreName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Genre Picture (Placeholder)
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.shade200, width: 2),
                  ),
                  // Placeholder Icon
                  child: const Icon(Icons.menu_book, size: 70, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Genre Name
              Text(
                genreName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),

              // Book Count (Extra detail)
              Text(
                '$bookCount Books available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 30, thickness: 1, color: Colors.deepPurple),


              // 3. Genre Description
              const Text(
                "Description:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                genreDescription,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              // Spacing before button
              const SizedBox(height: 50),

              // 4. Edit Genre Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Existing EditGenrePage par navigate karein
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // document ko pass karein
                        builder: (context) => EditGenrePage(document: widget.document),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    "Edit Genre Details",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Edit ke liye alag color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),

              const SizedBox(height: 15), // Spacing between Edit and Delete buttons

              // 5. Delete Genre Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteGenre(context), // Delete function call karein
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    "Delete Genre",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red, width: 2), // Border ko thoda prominent rakhein
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