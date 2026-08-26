import 'package:flutter/material.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:mboistats/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    LoggerService.logActivity(
      actionType: 'view_page',
      sectorCategory: 'auth',
      itemName: 'Halaman Login',
    );

    // Dengarkan perubahan state autentikasi (berguna untuk deep link callback)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        RecommendationService.clearLocalCache();
        final currentUser = Supabase.instance.client.auth.currentUser;
        LoggerService.logActivity(
          actionType: 'login_success',
          sectorCategory: 'auth',
          itemName: 'Login Google Sukses',
          userId: currentUser?.email ?? currentUser?.id,
        );
        final hasProfile = await RecommendationService.checkProfileExists();
        if (mounted) {
          if (hasProfile) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background illustration at the bottom
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Image.asset(
              'assets_v2/icons/login_bg.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Welcome Header Text
                  const Text(
                    'Selamat',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 45,
                      color: blueNormal,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'Datang',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 45,
                      color: Color(0xFF75C7EC), // blueLightActive
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'di MBOIStats+',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: orangeNormal,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Google SSO Login Button
                  Material(
                    color: blueNormal,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 3,
                    child: InkWell(
                      onTap: () async {
                        try {
                          final authResponse =
                              await AuthService.signInWithGoogle();
                          if (authResponse == null) {
                            // User membatalkan / menutup popup login
                            return;
                          }
                          // Navigasi ditangani otomatis oleh onAuthStateChange listener
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal masuk: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets_v2/icons/google_login.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Masuk dengan Google',
                              style: pjsBold14.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
