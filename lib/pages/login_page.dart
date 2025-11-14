import 'package:flutter/material.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:mboistats/theme.dart';
import 'package:provider/provider.dart';
import 'package:mboistats/services/supabase_db_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- PERBAIKAN: Ambil authService dari context ---
  // Hapus: final SupabaseAuthService _authService = SupabaseAuthService();
  // --- AKHIR PERBAIKAN ---
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    // --- PERBAIKAN: Ambil authService dari context ---
    final authService = context.read<SupabaseAuthService>();
    final bool success = await authService.signInWithGoogle(context);
    // --- AKHIR PERBAIKAN ---

    if (success) {
      print("Login Supabase Berhasil");

      if (mounted) {
        // --- PERBAIKAN DI SINI ---
        // Hapus 'await' karena checkCurrentUser() adalah fungsi 'void'
        context.read<SupabaseDbService>().checkCurrentUser();
        // --- AKHIR PERBAIKAN ---
        print("DEBUG: Refresh data favorit manual SELESAI.");
      }
      
      if (mounted) {
         Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
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
                  'assets/images/Mbois-stat Logo_Fix Putih.png', 
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
                              'assets/icons/google_icon.png', 
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