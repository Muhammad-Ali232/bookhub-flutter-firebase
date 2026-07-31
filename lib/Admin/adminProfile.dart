import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final admin = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController oldPassController = TextEditingController(); // Display old password
  TextEditingController newPassController = TextEditingController(); // Update only
  TextEditingController confirmPassController = TextEditingController(); // Update only

  String? profileImageBase64;
  bool isLoading = false;

  // Password visibility
  bool oldPassVisible = false;
  bool newPassVisible = false;
  bool confirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(admin.uid)
          .get();

      if (snap.exists) {
        final data = snap.data()!;
        nameController.text = data['name'] ?? '';
        profileImageBase64 = data['profileImage'];
        oldPassController.text = data['password'] ?? ''; // Show old password
        setState(() {});
      }
    } catch (e) {
      print("Admin profile load error: $e");
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      profileImageBase64 = base64Encode(bytes);
      setState(() {});
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Update name & profile image
      await FirebaseFirestore.instance
          .collection('users')
          .doc(admin.uid)
          .update({
        'name': nameController.text.trim(),
        'profileImage': profileImageBase64,
      });

      // Update password only if new password is entered
      if (newPassController.text.isNotEmpty &&
          confirmPassController.text.isNotEmpty) {
        // Reauthenticate using old password
        final cred = EmailAuthProvider.credential(
          email: admin.email!,
          password: oldPassController.text.trim(),
        );
        await admin.reauthenticateWithCredential(cred);

        // Update Firebase Auth password
        await admin.updatePassword(newPassController.text.trim());

        // Update password in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(admin.uid)
            .update({
          'password': newPassController.text.trim(),
        });

        // Clear new password fields after update
        newPassController.clear();
        confirmPassController.clear();

        // Update oldPassController to show the new password
        oldPassController.text = '';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      print("Profile update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Profile",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // PROFILE IMAGE
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.deepPurple.shade100,
                        backgroundImage: profileImageBase64 != null
                            ? MemoryImage(base64Decode(profileImageBase64!))
                            : null,
                        child: profileImageBase64 == null
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.deepPurple)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tap image to change",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // NAME
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Name cannot be empty";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // EMAIL
                    TextFormField(
                      initialValue: admin.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // OLD PASSWORD (display)
                    TextFormField(
                      controller: oldPassController,
                      obscureText: !oldPassVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(oldPassVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              oldPassVisible = !oldPassVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // NEW PASSWORD
                    TextFormField(
                      controller: newPassController,
                      obscureText: !newPassVisible,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(newPassVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              newPassVisible = !newPassVisible;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val!.isNotEmpty && val.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // CONFIRM PASSWORD
                    TextFormField(
                      controller: confirmPassController,
                      obscureText: !confirmPassVisible,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(confirmPassVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              confirmPassVisible = !confirmPassVisible;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (newPassController.text.isNotEmpty &&
                            val != newPassController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
