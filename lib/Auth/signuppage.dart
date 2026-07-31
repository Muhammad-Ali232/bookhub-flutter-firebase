import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookstore/Auth/loginpage.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool hidePass = true;
  bool hideConfirmPass = true;

  Uint8List? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  // Pick image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImage = bytes;
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // VALIDATION
  bool validateForm() {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String pass = passController.text.trim();
    String cPass = confirmPassController.text.trim();

    // Name validation
    if (name.isEmpty || name.length < 3) {
      showMessage("Full name must be at least 3 characters");
      return false;
    }
    if (!RegExp(r"^[a-zA-Z ]+$").hasMatch(name)) {
      showMessage("Name must only contain letters");
      return false;
    }

    // Email validation
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email)) {
      showMessage("Enter a valid email address");
      return false;
    }

    // Password length validation
    if (pass.length < 6 || pass.length > 10) {
      showMessage("Password must be 6 to 10 characters long");
      return false;
    }

    // Confirm password
    if (pass != cPass) {
      showMessage("Passwords do not match");
      return false;
    }

    // Image validation
    if (_profileImage == null) {
      showMessage("Please select a profile image");
      return false;
    }

    return true;
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // SAVE USER
  Future<void> signupUser() async {
    if (!validateForm()) return;

    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passController.text.trim();

    try {
      // Firebase Auth create user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("User ID is null");

      // Save user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'password': password,
        'profileImage': _base64Image ?? "",
        'role': 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMessage("Account Created Successfully!");

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));

    } on FirebaseAuthException catch (e) {
      String msg = "Signup failed";
      if (e.code == 'email-already-in-use') msg = "Email already registered";
      if (e.code == 'invalid-email') msg = "Invalid email format";
      if (e.code == 'weak-password') msg = "Password too weak";

      showMessage(msg);
    } catch (e) {
      showMessage("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage:
                    _profileImage != null ? MemoryImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Create Account ✨",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              "Register to get started",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 25),

            // NAME
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // EMAIL
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // PROFILE IMAGE INPUT
            TextField(
              readOnly: true,
              onTap: pickImage,
              decoration: InputDecoration(
                labelText: "Select Profile Image",
                prefixIcon: const Icon(Icons.image),
                suffixIcon: const Icon(Icons.upload),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // PASSWORD
            TextField(
              controller: passController,
              obscureText: hidePass,
              decoration: InputDecoration(
                labelText: "Password (6 - 10 chars)",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      hidePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => hidePass = !hidePass),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // CONFIRM PASSWORD
            TextField(
              controller: confirmPassController,
              obscureText: hideConfirmPass,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(hideConfirmPass
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => hideConfirmPass = !hideConfirmPass),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),

            // SIGN UP BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: signupUser,
                child: const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  child: const Text("Login"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
