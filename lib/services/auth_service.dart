import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/auth_config.dart';
import 'package:mboistats/services/logger_service.dart';

/// Service untuk menangani otentikasi pengguna menggunakan Native Google Sign-In
/// terintegrasi dengan Supabase Auth (metode `signInWithIdToken`).
class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Menjalankan alur Native Google Sign-In.
  ///
  /// Alur Login:
  /// 1. Memunculkan bottom sheet / pop-up native akun Google di HP.
  /// 2. Mengambil [idToken] dan [accessToken] dari SDK Google Play Services / iOS SDK.
  /// 3. Mengirimkan [idToken] tersebut ke `supabase.auth.signInWithIdToken()`.
  ///
  /// Mengembalikan [AuthResponse] jika login berhasil, atau `null` jika pengguna
  /// membatalkan/menutup pop-up Google.
  /// Melemparkan error jika terjadi kegagalan otentikasi.
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      LoggerService.logActivity(
        actionType: 'click_login_google',
        sectorCategory: 'auth',
        itemName: 'Masuk dengan Google (Native)',
      );

      // 1. Inisialisasi GoogleSignIn SDK dengan Web Client ID
      await GoogleSignIn.instance.initialize(
        serverClientId: AuthConfig.webClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? AuthConfig.iosClientId
            : null,
      );

      // 2. Panggil bottom sheet native akun Google
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3. Ambil autentikasi dan ID Token dari Google (synchronous getter di google_sign_in 7.x)
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw 'Gagal mendapatkan Google ID Token dari Google Play Services.';
      }

      // 4. Kirim ID Token ke Supabase Auth secara native (tanpa OAuth Browser/Webview)
      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      LoggerService.logActivity(
        actionType: 'login_success',
        sectorCategory: 'auth',
        itemName: 'Login Google Native Sukses',
        userId: authResponse.user?.email ?? authResponse.user?.id,
      );

      return authResponse;
    } on AuthException catch (e) {
      LoggerService.logActivity(
        actionType: 'login_failed',
        sectorCategory: 'auth',
        itemName: 'Supabase AuthException: ${e.message}',
      );
      throw 'Otentikasi Supabase gagal: ${e.message}';
    } catch (e) {
      print('Native Google Sign-In failed or canceled ($e). Attempting Supabase OAuth fallback...');
      return await _signInWithOAuthFallback();
    }
  }

  /// Fallback menggunakan Supabase OAuth Browser Flow
  static Future<AuthResponse?> _signInWithOAuthFallback() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.mboistats://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return null; // Redirection dan login ditangani oleh Supabase onAuthStateChange listener
    } catch (e) {
      LoggerService.logActivity(
        actionType: 'login_failed',
        sectorCategory: 'auth',
        itemName: 'OAuth Fallback Error: $e',
      );
      throw 'Gagal masuk dengan Google: $e';
    }
  }

  /// Keluar dari sesi Supabase Auth dan Google Sign-In.
  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Abaikan jika Google Sign-In belum terinisialisasi
    }
    await _supabase.auth.signOut();
  }
}
