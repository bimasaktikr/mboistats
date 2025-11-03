import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import
import 'dart:async'; // Import untuk Timer

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 0.0; // Mulai dari 0
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // Mulai animasi fade-in
    Timer(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          opacity = 1.0;
        });
      }
    });

    // Panggil fungsi pengecekan login
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tunggu animasi fade-in selesai dan beri sedikit jeda
    await Future.delayed(Duration(seconds: 2));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cek status login, default-nya false (belum login)
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Mulai fade-out
    if (mounted) {
      setState(() {
        opacity = 0.0;
      });
    }
    await Future.delayed(Duration(seconds: 1));

    // Navigasi berdasarkan status login
    if (!mounted) return;
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: opacity, // Gunakan state opacity
          duration: Duration(seconds: 1),
          child: Image.asset(
            'assets/images/Mbois-stat Logo_Fix Putih.png',
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
