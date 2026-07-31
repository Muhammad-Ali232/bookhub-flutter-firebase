import 'dart:convert';
import 'dart:ui';
import 'package:bookstore/Auth/loginpage.dart';
import 'package:bookstore/Users/Profilepage.dart';
import 'package:bookstore/Users/bookdetailspage.dart';
import 'package:bookstore/Users/cartItempage.dart';
import 'package:bookstore/Users/myBooks.dart';
import 'package:bookstore/Users/myorder.dart';
import 'package:bookstore/Users/wishListpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String? userId;
  const HomePage({super.key, this.userId});

  static Widget newInstance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return HomePage(userId: uid);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (snap.exists) setState(() => userData = snap.data());
    } catch (e) {
      print("User fetch error: $e");
    }
  }

  // ------------------------ LOGIN DIALOG --------------------------
  void showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("You must login first."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------

  int _selectedIndex = 0;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBooksPage()));
    } 
    else if (index == 2) {
      if (FirebaseAuth.instance.currentUser == null) {
        showLoginDialog();
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
      }
    } 
    else if (index == 3) {
      if (FirebaseAuth.instance.currentUser == null) {
        showLoginDialog();
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
      }
    } 
    else if (index == 4) {
      if (FirebaseAuth.instance.currentUser == null) {
        showLoginDialog();
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfilePage()));
      }
    } 
    else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.deepPurple,
              centerTitle: true,
              automaticallyImplyLeading: true,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.shade100,
                    ),
                    child: const Icon(
                      Icons.book,
                      size: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "BookHub",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              actions: [
  if (FirebaseAuth.instance.currentUser == null)
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
      child: const Text(
        "Login",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    )
  else
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        // After logout → refresh screen by replacing page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
    ),
]

            )
          : null,
      drawer: _selectedIndex == 0 ? buildDrawer(context) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          buildHomeScreen(),
          const Center(child: Text("All Books")),
          const Center(child: Text("Cart")),
          const Center(child: Text("Wishlist")),
          const Center(child: Text("Profile")),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'All Books'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: (userData != null &&
                          userData!['profileImage'] != null &&
                          (userData!['profileImage'] as String).isNotEmpty)
                      ? MemoryImage(base64Decode(userData!['profileImage']))
                      : null,
                  child: (userData == null ||
                          userData!['profileImage'] == null ||
                          (userData!['profileImage'] as String).isEmpty)
                      ? const Icon(Icons.person,
                          size: 45, color: Colors.deepPurple)
                      : null,
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData?['name'] ?? "Guest User",
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(userData?['email'] ?? "Login to continue",
                        style: const TextStyle(color: Colors.white70,fontSize: 12)),
                  ],
                )
              ],
            ),
          ),

          drawerTile(Icons.home, "Home", () => setState(() => _selectedIndex = 0)),

          drawerTile(Icons.book, "All Books", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBooksPage()));
          }),

          drawerTile(Icons.shopping_cart, "My Cart", () {
            if (FirebaseAuth.instance.currentUser == null) {
              showLoginDialog();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CartPage()));
            }
          }),

          drawerTile(Icons.receipt_long, "My Order", () {
            if (FirebaseAuth.instance.currentUser == null) {
              showLoginDialog();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyOrdersPage()));
            }
          }),

          drawerTile(Icons.person, "My Profile", () {
            if (FirebaseAuth.instance.currentUser == null) {
              showLoginDialog();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyProfilePage()));
            }
          }),

          drawerTile(Icons.favorite, "Wishlist", () {
            if (FirebaseAuth.instance.currentUser == null) {
              showLoginDialog();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WishlistPage()));
            }
          }),

          drawerTile(Icons.logout, "Logout", () async {
            await FirebaseAuth.instance.signOut();
            setState(() {
              userData = null;
              _selectedIndex = 0;
            });
          }),
        ],
      ),
    );
  }

  ListTile drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // ---------------------- HOME UI ------------------------------

  Widget buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: (val) => setState(() => searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search by title, author, or genre...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Bestsellers",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          SizedBox(
            height: 240,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('cartCount', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bestsellerBooks = snapshot.data!.docs.where((book) {
  final data = book.data()! as Map<String, dynamic>;
  final cartCount = data['cartCount'] ?? 0;

  if (cartCount < 3) return false;   // bestseller condition

  final q = searchQuery.toLowerCase();   // search filter
  return data['title'].toString().toLowerCase().contains(q) ||
         data['author'].toString().toLowerCase().contains(q) ||
         data['genre'].toString().toLowerCase().contains(q);
}).toList();


                if (bestsellerBooks.isEmpty) {
                  return const Center(child: Text("No bestsellers yet"));
                }

                return ScrollConfiguration(
  behavior: ScrollConfiguration.of(context).copyWith(
    dragDevices: {
      PointerDeviceKind.touch,      // Mobile finger drag
      PointerDeviceKind.mouse,      // Mouse drag
      PointerDeviceKind.trackpad,   // Laptop trackpad
    },
  ),
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: bestsellerBooks.length,
    itemBuilder: (context, index) {
      final book = bestsellerBooks[index];
      final data = book.data()! as Map<String, dynamic>;

      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(data: data, id: book.id),
          ),
        ),
        child: BookCardUI(data: data),
      );
    },
  ),
);

              },
            ),
          ),

          const SizedBox(height: 25),

          const Text("New Arrivals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = snapshot.data!.docs.where((book) {
                final data = book.data()! as Map<String, dynamic>;
                final q = searchQuery.toLowerCase();
                return data['title']
                        .toString()
                        .toLowerCase()
                        .contains(q) ||
                    data['author']
                        .toString()
                        .toLowerCase()
                        .contains(q) ||
                    data['genre']
                        .toString()
                        .toLowerCase()
                        .contains(q);
              }).toList();

              if (books.isEmpty) {
                return const Center(child: Text("No books found"));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: books.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return NewArrivalBook(
                      data: book.data()! as Map<String, dynamic>,
                      id: book.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ----------------- EXTRA CLASSES -------------------

class BookCardUI extends StatelessWidget {
  final Map<String, dynamic> data;
  const BookCardUI({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 6,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              image: (data['coverImage'] != null &&
                      (data['coverImage'] as String).isNotEmpty)
                  ? DecorationImage(
                      image: MemoryImage(
                          base64Decode(data['coverImage'])),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: (data['coverImage'] == null ||
                    (data['coverImage'] as String).isEmpty)
                ? const Icon(Icons.book, size: 50)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(data['title'] ?? 'No Title',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(data['author'] ?? 'Unknown',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Text("PKR ${data['price']?.toString() ?? '0'}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewArrivalBook extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const NewArrivalBook({super.key, required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookDetailPage(data: data, id: id))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 6,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                image: (data['coverImage'] != null &&
                        (data['coverImage'] as String).isNotEmpty)
                    ? DecorationImage(
                        image:
                            MemoryImage(base64Decode(data['coverImage'])),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: (data['coverImage'] == null ||
                      (data['coverImage'] as String).isEmpty)
                  ? const Icon(Icons.book, size: 50)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(data['title'] ?? 'No Title',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(data['author'] ?? 'Unknown',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(data['genre'] ?? 'Unknown',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text("PKR ${data['price']?.toString() ?? '0'}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
