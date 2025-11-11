import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceCustom {
  // --- PERBAIKAN 1: Jadikan variabel ini 'static const' ---
  // Ini menyelesaikan error "instance member can't be accessed in an initializer"
  // karena 'static const' bisa diakses dari mana saja.
  static const String _googleServerClientId = "1048599871385-9bkgj0pg9obba8rhejo2slrl2o28t5le.apps.googleusercontent.com";
  
  // Jadikan ini static const juga untuk konsistensi
  static const String _serverUrl = 'https://api.server-anda.com/api';
  // --- AKHIR PERBAIKAN 1 ---


  // --- PERBAIKAN 2: Sederhanakan Singleton ---
  // 1. Buat instance static dan panggil constructor private
  static final AuthServiceCustom instance =
      AuthServiceCustom._privateConstructor();

  // 2. Deklarasikan semua final fields Anda
  final GoogleSignIn _googleSignIn;
  final _storage = const FlutterSecureStorage();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 3. Buat SATU constructor private yang menginisialisasi SEMUANYA
  AuthServiceCustom._privateConstructor()
      : _googleSignIn = GoogleSignIn(
          // Sekarang ini valid karena _googleServerClientId adalah 'static const'
          serverClientId: _googleServerClientId,
        );
  // --- AKHIR PERBAIKAN 2 ---


  // --- TAMBAHAN BARU: "SUMBER KEBENARAN" ---
  /// ValueNotifier global untuk status user.
  /// Widget lain (seperti HomePage) akan "mendengarkan" perubahan ini.
  /// Dimulai dengan null (tidak diketahui/logout).
  ValueNotifier<User?> currentUser = ValueNotifier(null);
  // --- AKHIR TAMBAHAN ---

  // Constructor factory (tidak berubah)
  factory AuthServiceCustom() {
    return instance;
  }

  // HAPUS: Constructor _internal() yang salah
  // AuthServiceCustom._internal() ...

  /// [init] harus dipanggil di main.dart
  /// Ini mendengarkan perubahan status login dari Firebase (termasuk saat startup)
  Future<void> init() async {
    _firebaseAuth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      print(
          "DEBUG [AuthService]: AuthState Changed. User is: ${user?.uid ?? 'null'}");
    });
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      // 1. Memulai alur login Google
      print("DEBUG: Memulai login Google...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("DEBUG: Login Google dibatalkan oleh pengguna.");
        return false;
      }

      // 2. Mendapatkan idToken (diperlukan untuk Firebase)
      print("DEBUG: Login Google sukses. Mencoba login ke Firebase...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mendapatkan Google ID Token.")),
        );
        return false;
      }

      // 3. Login ke Firebase menggunakan idToken
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mendapatkan User Firebase.")),
        );
        return false;
      }

      print("DEBUG: Login Firebase BERHASIL. User UID: ${user.uid}");

      // --- PERUBAHAN: PERBARUI VALUE NOTIFIER ---
      // Ini akan memicu ValueListenableBuilder di HomePage untuk membangun ulang
      currentUser.value = user;
      // --- AKHIR PERUBAHAN ---

      // --- PERUBAHAN DI SINI: MODE PENGEMBANGAN (MOCK) ---
      print("DEBUG: Backend belum siap. Memalsukan respons server...");
      await Future.delayed(const Duration(seconds: 1));

      final String username = user.displayName ?? 'Pengguna Google';
      final String email = user.email ?? 'Tidak ada email';
      final String fakeSessionToken = 'TOKEN_PALSU_DARI_FLUTTER_12345';

      // 5. Simpan token sesi palsu & data pengguna
      await _storage.write(key: 'session_token', value: fakeSessionToken);
      await _storage.write(key: 'username', value: username);
      await _storage.write(key: 'email', value: email);

      print(
          "DEBUG: Login palsu berhasil. Token: $fakeSessionToken, User: $username");
      return true;
      // --- AKHIR MODE PENGEMBANGAN ---

    } catch (e) {
      print("Error saat signInWithGoogle: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      return false;
    }
  }

  // Fungsi Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut(); // <-- PENTING: Logout juga dari Firebase
    await _storage.delete(key: 'session_token');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'email');

    // --- PERUBAHAN: PERBARUI VALUE NOTIFIER ---
    // Ini akan memicu ValueListenableBuilder di HomePage untuk membangun ulang
    currentUser.value = null;
    // --- AKHIR PERUBAHAN ---
  }

  // Cek status login (sekarang bisa dicek secara sinkron)
  bool isLoggedIn() {
    return currentUser.value != null;
  }

  // Mengambil data pengguna
  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }
}