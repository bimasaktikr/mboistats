import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Kita import 'main.dart' untuk menggunakan variabel 'supabase' global
import 'package:mboistats/main.dart'; 

class SupabaseAuthService {
  static final String _googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleWebClientId, 
  );
  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("DEBUG: Login Google dibatalkan oleh pengguna.");
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mendapatkan Google ID Token.")),
        );
        return false;
      }
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
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await supabase.auth.signOut(); // <-- Ini juga menggunakan 'supabase' global
    print("DEBUG: Logout dari Supabase & Google berhasil.");
  }
  bool isLoggedIn() {
    return supabase.auth.currentUser != null; // <-- Ini juga menggunakan 'supabase' global
  }
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
  User? get currentUser => supabase.auth.currentUser;
  String? getUsername() {
    return supabase.auth.currentUser?.userMetadata?['full_name'];
  }
  String? getEmail() {
    return supabase.auth.currentUser?.email;
  }
}