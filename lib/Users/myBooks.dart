import 'dart:convert';
import 'package:bookstore/Users/bookdetailspage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  String selectedFilter = 'None';
  String selectedAuthor = 'All';
  String selectedGenre = 'All';

  List<String> authors = ['All'];
  List<String> genres = ['All'];

  @override
  void initState() {
    super.initState();
    loadFilters();
  }

  Future<void> loadFilters() async {
    final query = await FirebaseFirestore.instance.collection('books').get();

    Set<String> authorSet = {};
    Set<String> genreSet = {};

    for (var doc in query.docs) {
      final data = doc.data();
      if (data['author'] != null && data['author'].toString().isNotEmpty) {
        authorSet.add(data['author']);
      }
      if (data['genre'] != null && data['genre'].toString().isNotEmpty) {
        genreSet.add(data['genre']);
      }
    }

    setState(() {
      authors = ['All', ...authorSet];
      genres = ['All', ...genreSet];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Books", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          // ---------------- Filters UI ----------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  children: [
                    // ------------ Author Filter ------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.filter_list, size: 20, color: Colors.deepPurple),
                              SizedBox(width: 4),
                              Text("by Author", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          DropdownButton<String>(
                            value: selectedAuthor,
                            isExpanded: true,
                            items: authors
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) => setState(() => selectedAuthor = value!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ------------ Genre Filter ------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.filter_list,
                                  size: 20, color: Colors.deepPurple),
                              SizedBox(width: 4),
                              Text("by Genre",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          DropdownButton<String>(
                            value: selectedGenre,
                            isExpanded: true,
                            items: genres
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) => setState(() => selectedGenre = value!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ---------------- Sorting ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sort by:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 180,
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        isExpanded: true,
                        items: <String>[
                          'None',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Popularity',
                          'New Release',
                          'Old Release'
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) =>
                            setState(() => selectedFilter = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ---------------- Heading ----------------
          const Center(
            child: Text(
              "All Books",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          // ---------------- BOOKS GRID ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ---------------- FILTER ----------------
                List<DocumentSnapshot> books = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (selectedAuthor != 'All' &&
                      data['author'] != selectedAuthor) return false;

                  if (selectedGenre != 'All' &&
                      data['genre'] != selectedGenre) return false;

                  return true;
                }).toList();

                // ---------------- SORT ----------------
                books.sort((a, b) {
                  final A = a.data() as Map<String, dynamic>;
                  final B = b.data() as Map<String, dynamic>;

                  switch (selectedFilter) {
                    case 'Price: Low to High':
                      return (A['price'] ?? 0).compareTo(B['price'] ?? 0);

                    case 'Price: High to Low':
                      return (B['price'] ?? 0).compareTo(A['price'] ?? 0);

                    case 'Popularity':
                      return (B['soldCount'] ?? 0)
                          .compareTo(A['soldCount'] ?? 0);

                    case 'New Release':
                      return (B['createdAt']?.toDate() ?? DateTime(2000))
                          .compareTo(A['createdAt']?.toDate() ?? DateTime(2000));

                    case 'Old Release':
                      return (A['createdAt']?.toDate() ?? DateTime(2000))
                          .compareTo(B['createdAt']?.toDate() ?? DateTime(2000));

                    default:
                      return 0;
                  }
                });

                if (books.isEmpty) {
                  return const Center(child: Text("No books found."));
                }

                // ---------------- GRID VIEW ----------------
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final data = books[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(
                                data: data, id: books[index].id),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: data['coverImage'] != null &&
                                      data['coverImage'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                      child: Image.memory(
                                        base64Decode(data['coverImage']),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.book, size: 50),
                            ),
                            const SizedBox(height: 6),
                            Text(data['title'] ?? 'No Title',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(data['author'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 12)),
                            Text(data['genre'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 10)),
                            Text("PKR ${data['price']}",
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
