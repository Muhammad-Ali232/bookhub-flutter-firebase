import 'package:bookstore/Admin/GenreCrud/createGenre.dart';
import 'package:bookstore/Admin/GenreCrud/genreDetail.dart';
import 'package:flutter/material.dart';
// Firestore ko use karne ke liye zaruri imports
import 'package:cloud_firestore/cloud_firestore.dart'; 
// Assuming createGenre.dart is CreateGenrePage
// Import naya detail page
// Edit page ab Detail page se open hoga

class GenresPage extends StatefulWidget {
  const GenresPage({super.key});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  // CollectionReference ko define karein, jaisa ki image mein dikhaya gaya hai
  final CollectionReference _genresCollection = 
      FirebaseFirestore.instance.collection('genres');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Genres", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Genre Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Ensure this matches your Create page class name
                      builder: (context) => const CreateGenrePage(), 
                    ),
                  );
                },
                icon: const Icon(Icons.library_add, color: Colors.white),
                label: const Text(
                  "Add New Genre",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            const SizedBox(height: 20),

            const Text(
              "Available Genres",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),

            // Genres Grid - Ab StreamBuilder ka use ho raha hai
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Stream set karein collection ke snapshots par
                stream: _genresCollection.snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  // Error Handling
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)));
                  }

                  // Loading State 
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // Data milne par
                  if (snapshot.hasData) {
                    final genresData = snapshot.data!.docs;
                    
                    if (genresData.isEmpty) {
                       return const Center(
                          child: Text(
                              'No genres created yet. Please add a new genre.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        );
                    }

                    // GridView.builder for displaying genres dynamically
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0, 
                      ),
                      itemCount: genresData.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot document = genresData[index];
                        final data = document.data()! as Map<String, dynamic>;
                        
                        // Data fields ko extract karein
                        final genreName = data['name'] ?? 'Untitled Genre';
                        // bookCount field ko check karein
                        final bookCount = data['bookCount'] != null 
                                            ? '${data['bookCount']} Books' 
                                            : '0 Books';
                        
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: InkWell(
                            // --- UPDATED onTap ---
                            onTap: () {
                              // Ab Detail Page par navigate hoga
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Document ko pass kar rahe hain Detail page mein
                                  builder: (context) => GenreDetailPage(document: document),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(Icons.category,
                                        size: 30, color: Colors.deepPurple),
                                  ),
                                  const SizedBox(height: 15),

                                  // Genre Name
                                  Text(
                                    genreName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis, 
                                  ),
                                  const SizedBox(height: 5),

                                  // Book Count
                                  Text(
                                    bookCount,
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  
                  // Default fallback
                  return const Center(child: Text("Start adding genres!"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}