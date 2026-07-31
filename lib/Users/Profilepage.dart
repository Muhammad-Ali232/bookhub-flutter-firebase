import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController oldPassController = TextEditingController();
  TextEditingController newPassController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  String? profileImageBase64;

  bool isLoading = false;

  // ---------- PASSWORD VISIBILITY ----------
  bool oldPassVisible = false;
  bool newPassVisible = false;
  bool confirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snap.exists) {
        final data = snap.data()!;
        nameController.text = data['name'] ?? '';
        profileImageBase64 = data['profileImage'];
        setState(() {});
      }
    } catch (e) {
      print("Profile load error: $e");
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
      // --------- UPDATE NAME & IMAGE ----------
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'profileImage': profileImageBase64,
      });

      // --------- PASSWORD UPDATE ----------
      if (oldPassController.text.isNotEmpty &&
          newPassController.text.isNotEmpty) {

        // REAUTHENTICATE
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassController.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);

        // UPDATE PASSWORD in Firebase Auth
        await user.updatePassword(newPassController.text.trim());

        // ---------------- UPDATE PASSWORD in Firestore ----------------
        // ⚠️ Warning: Storing plain text passwords is unsafe
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'password': newPassController.text.trim(),
        });
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
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white),
        ),
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
                    // ---------------- PROFILE IMAGE ----------------
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

                    // ---------------- NAME ----------------
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

                    // ---------------- EMAIL ----------------
                    TextFormField(
                      initialValue: user.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---------------- OLD PASSWORD ----------------
                    TextFormField(
                      controller: oldPassController,
                      obscureText: !oldPassVisible,
                      decoration: InputDecoration(
                        labelText: "Old Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            oldPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              oldPassVisible = !oldPassVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------------- NEW PASSWORD ----------------
                    TextFormField(
                      controller: newPassController,
                      obscureText: !newPassVisible,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            newPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
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

                    // ---------------- CONFIRM PASSWORD ----------------
                    TextFormField(
                      controller: confirmPassController,
                      obscureText: !confirmPassVisible,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmPassVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
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

                    // ---------------- SAVE BUTTON ----------------
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
