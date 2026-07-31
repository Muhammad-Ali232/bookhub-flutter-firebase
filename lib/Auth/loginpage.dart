import 'package:bookstore/Admin/adminhome.dart';
import 'package:bookstore/Users/home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookstore/Auth/signuppage.dart';

class LoginPage extends StatefulWidget {
  final bool returnToHome;
  final Widget? redirectPage;

  const LoginPage({
    super.key,
    this.returnToHome = true,
    this.redirectPage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePass = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();   // ✔ FORM KEY

  // ------------------- FORGOT PASSWORD FUNCTION -------------------
  Future<void> resetPassword() async {
    String email = "";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Password"),
        content: TextField(
          onChanged: (value) => email = value.trim(),
          decoration: const InputDecoration(
            labelText: "Enter your email",
            prefixIcon: Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (email.isEmpty) return;

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  // ------------------------ LOGIN FUNCTION ------------------------
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;  // ✔ VALID NA HO TW AAGY NA JAO
    }

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user == null) throw Exception("FirebaseAuth returned null user");

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) throw Exception("User document not found in Firestore");

      final data = doc.data()!;
      final role = data['role'] ?? 'User';

      if (role == 'Admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminHomePage()));
      } else {
        if (!widget.returnToHome && widget.redirectPage != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => widget.redirectPage!));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => HomePage(userId: user.uid)));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    }

    setState(() => _isLoading = false);
  }

  // ------------------------ UI DESIGN ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F3FF),
       appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 28),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
  ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ---------------------- LOGO ----------------------
            Column(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple.shade100,
                  ),
                  child: const Center(
                    child: Icon(Icons.book, size: 55, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "BookHub",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Welcome Back 👋",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ---------------------- LOGIN CARD ----------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),

              child: Form(
                key: _formKey,  // ✔ FORM START
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EMAIL
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$")
                            .hasMatch(value.trim())) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: hidePass,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => hidePass = !hidePass),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Password is required";
                        }
                        if (value.length < 6) {
                          return "Minimum 6 characters required";
                        }
                        return null;
                      },
                    ),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                    ),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // SIGNUP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            );
                          },
                          child: const Text("Sign Up"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
