import 'dart:async';
import 'package:bookstore/Users/home.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 10), () {
  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const HomePage(),
    ),
  );
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---- Logo ----
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.book,
                    size: 60,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                // ---- App Name ----
                const Text(
                  "BookHub",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ---- Powered by text at bottom ----
       Positioned(
  bottom: 20,
  left: 0,
  right: 0,
  child: Center(
    child: Text.rich(
      TextSpan(
        text: "Powered by ",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        children: const [
          TextSpan(
            text: "ANSH",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, 
              color: Colors.white
            ),
          ),
        ],
      ),
    ),
  ),
),

        ],
      ),
    );
  }
}
