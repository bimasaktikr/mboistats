import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- PERBAIKAN DI SINI ---
// Kita import 'main.dart' untuk menggunakan variabel 'supabase' global
import 'package:mboistats/main.dart'; 

// HAPUS BARIS INI:
// final supabase = Supabase.instance.client;
// --- AKHIR PERBAIKAN ---

class SupabaseAuthService {
  // --- PERSIAPAN ---
  // Ambil Web Client ID yang Anda simpan di .env
  // Ini adalah ID dari Google Cloud Console (Tipe Web)
  static final String _googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Gunakan serverClientId agar kita bisa mendapatkan idToken
    serverClientId: _googleWebClientId, 
  );
  
  // --- Alur Sign In Baru ---
  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      // 1. Memulai alur login Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("DEBUG: Login Google dibatalkan oleh pengguna.");
        return false;
      }

      // 2. Mendapatkan idToken (diperlukan untuk Supabase)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mendapatkan Google ID Token.")),
        );
        return false;
      }
      
      // 3. Login ke Supabase menggunakan idToken
      // 'supabase' di sini sekarang merujuk ke variabel global dari main.dart
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final User? user = response.user;
      if (user == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mendapatkan User Supabase.")),
        );
        return false;
      }
      
      print("DEBUG: Login Supabase BERHASIL. User UID: ${user.id}");
      return true;

    } catch (e) {
      print("Error saat signInWithGoogle (Supabase): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      return false;
    }
  }

  // --- Fungsi Sign Out Baru ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await supabase.auth.signOut(); // <-- Ini juga menggunakan 'supabase' global
    print("DEBUG: Logout dari Supabase & Google berhasil.");
  }
  
  // --- Fungsi Cek Status Login ---
  bool isLoggedIn() {
    return supabase.auth.currentUser != null; // <-- Ini juga menggunakan 'supabase' global
  }
  
  // --- Stream untuk status auth (penting untuk UI) ---
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;
  
  // --- (Opsional) Mengambil data pengguna ---
  // Di Supabase, data user (seperti nama) disimpan di 'user_metadata'
  String? getUsername() {
    return supabase.auth.currentUser?.userMetadata?['full_name'];
  }
  
  String? getEmail() {
    return supabase.auth.currentUser?.email;
  }
}