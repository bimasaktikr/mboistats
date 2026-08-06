import 'package:flutter/material.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 1.0; // Nilai opasitas awal
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    // Menggunakan Future.delayed untuk mengatur animasi
    Future.delayed(const Duration(seconds: 2), () async {
      setState(() {
        opacity = 0.0; // Mengubah opasitas menjadi 0 untuk menghilangkan tulisan
      });

      final session = Supabase.instance.client.auth.currentSession;

      Future.delayed(const Duration(seconds: 1), () async {
        if (mounted) {
          if (session == null) {
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            // Cek apakah perangkat sudah menyelesaikan onboarding sebelumnya (dengan timeout 1.5 detik)
            final hasProfile = await RecommendationService.checkProfileExists()
                .timeout(const Duration(milliseconds: 1500), onTimeout: () => true);
            
            if (hasProfile) {
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              Navigator.pushReplacementNamed(context, '/onboarding');
            }
          }
        }
      });
    });

    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFF1F7BA4),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: opacity,
              duration: Duration(seconds: 1),
              child: Image.asset(
                'assets/images/Mbois-stat Logo_Fix Putih.png',
                width: 200,
                height: 200,
              ),
            ),
            AnimatedPositioned(
              top: 130, // Ganti nilai top sesuai keinginan
              duration: Duration(seconds: 1),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: Duration(seconds: 1),
                // child: const Text(
                //   "mboistats+",
                //   style: TextStyle(
                //     fontSize: 32,
                //     fontWeight: FontWeight.bold,
                //     color: Color.fromARGB(221, 219, 95, 12),
                //   ),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
