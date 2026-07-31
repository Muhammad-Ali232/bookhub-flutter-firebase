import 'package:bookstore/Users/myorder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postalController = TextEditingController();
  final notesController = TextEditingController();

  bool _loading = false;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Auto-fill email from FirebaseAuth
        emailController.text = user.email ?? "";

        // Fetch name & phone from Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          nameController.text = data['name'] ?? "";
          phoneController.text = data['phone'] ?? "";
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }

    setState(() {
      _loadingUser = false; // stop loading indicator
    });
  }

  Future<void> submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    // Fetch cart items
    final cartItems = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: userId)
        .get();

    if (cartItems.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Your cart is empty!")));
      setState(() => _loading = false);
      return;
    }

    double total = 0;
    List<Map<String, dynamic>> orderItems = [];

    for (var item in cartItems.docs) {
      double price = item['price'] ?? 0;
      int qty = item['qty'] ?? 1;
      total += price * qty;

      orderItems.add({
        'title': item['title'],
        'author': item['author'],
        'price': price,
        'qty': qty,
        'image': item['coverImage'],
      });
    }

    // Save order with auto-generated ID
    final orderRef = await FirebaseFirestore.instance.collection('orders').add({
      'userId': userId,
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'postalCode': postalController.text.trim(),
      'notes': notesController.text.trim(),
      'items': orderItems,
      'total': total,
      'status': 'Pending',
      'createdAt': Timestamp.now(),
    });

    // Update order with its own ID
    await orderRef.update({'orderId': orderRef.id});

    // Clear cart
    for (var doc in cartItems.docs) {
      await doc.reference.delete();
    }

    setState(() => _loading = false);

    // Show Order Placed dialog with details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Order Placed ✅"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Order ID: ${orderRef.id}"),
              const SizedBox(height: 8),
              Text("Total: ₨${total.toStringAsFixed(2)}"),
              const SizedBox(height: 8),
              Text("Items:"),
              ...orderItems.map(
                (item) => Text(
                  "${item['title']} x${item['qty']} (₨${item['price']})",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close form page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersPage()),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Delivery Details", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),

                    // Email (read-only)
                    TextFormField(
                      controller: emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email (auto-filled)",
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Phone
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),

                    // Address
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),

                    // City
                    TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: "City"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),

                    // Postal Code
                    TextFormField(
                      controller: postalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Postal Code",
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (optional)",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Place Order",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
