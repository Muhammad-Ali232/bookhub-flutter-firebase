import 'package:bookstore/Admin/TitleCrud/createTitle.dart';
import 'package:bookstore/Admin/TitleCrud/titleDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TitlesPage extends StatefulWidget {
  const TitlesPage({super.key});

  @override
  State<TitlesPage> createState() => _TitlesPageState();
}

class _TitlesPageState extends State<TitlesPage> {
  // Firestore Collection
  final CollectionReference _titlesCollection =
      FirebaseFirestore.instance.collection('titles');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Titles", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Title Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTitlePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box, color: Colors.white),
                label: const Text(
                  "Add New Title",
                  style: TextStyle(
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
            const SizedBox(height: 20),

            const Text(
              "Available Titles",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),

            // StreamBuilder For Titles
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _titlesCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData) {
                    final titlesData = snapshot.data!.docs;

                    if (titlesData.isEmpty) {
                      return const Center(
                        child: Text(
                          'No titles created yet. Please add a new title.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: titlesData.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot document = titlesData[index];
                        final data =
                            document.data()! as Map<String, dynamic>;

                        final titleName =
                            data['Title Name'] ?? 'Untitled Title';
                        final bookCount = data['bookCount'] != null
                            ? '${data['bookCount']} Books'
                            : '0 Books';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TitleDetailPage(
                                    document: document,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.deepPurple.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                    child: const Icon(Icons.title,
                                        size: 32,
                                        color: Colors.deepPurple),
                                  ),
                                  const SizedBox(height: 15),

                                  Text(
                                    titleName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),

                                  Text(
                                    bookCount,
                                    style:
                                        const TextStyle(color: Colors.grey),
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

                  return const Center(child: Text("Start adding titles!"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
