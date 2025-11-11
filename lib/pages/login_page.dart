import 'package:flutter/material.dart';
import 'package:mboistats/services/auth_service_custom.dart'; // <-- GANTI SERVICE
import 'package:mboistats/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- LOGIKA DIPERBARUI ---
  final AuthServiceCustom _authService = AuthServiceCustom();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final bool success = await _authService.signInWithGoogle(context);

    if (success) {
      // Login berhasil
      print("Login Berhasil via Server Kustom");
      // Navigasi ke halaman utama dan hapus semua halaman sebelumnya
      if (mounted) {
         Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    } else {
      // Login gagal atau dibatalkan
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- AKHIR LOGIKA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/Mbois-stat Logo_Fix Putih.png', // Logo Anda
                  height: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'Selamat Datang di MBOIStatS+',
                  textAlign: TextAlign.center,
                  style: bold18.copyWith(color: dark1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk menyimpan data favorit Anda.',
                  textAlign: TextAlign.center,
                  style: regular14.copyWith(color: dark2),
                ),
                const SizedBox(height: 48),

                // Tombol Google Sign-In
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: dark1,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: dark4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _handleGoogleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/google_icon.png', // Pastikan Anda punya aset ini
                              height: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Masuk dengan Google',
                              style: semibold14.copyWith(color: dark1),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

