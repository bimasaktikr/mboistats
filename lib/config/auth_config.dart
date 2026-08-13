/// Konfigurasi Kredensial untuk Native Google Sign-In & Supabase Auth.
class AuthConfig {
  /// Web Client ID dari Google Cloud Console (OAuth 2.0 Client IDs -> Web application).
  ///
  /// WAJIB:
  /// 1. Gunakan ID ini sebagai [serverClientId] pada SDK GoogleSignIn.
  /// 2. Daftarkan Web Client ID dan Web Client Secret ini di Supabase Dashboard:
  ///    Authentication -> Providers -> Google.
  static const String webClientId =
      '514445291536-chdl933f0j39uuas2dsnb132boen68s7.apps.googleusercontent.com';

  /// iOS Client ID dari Google Cloud Console (OAuth 2.0 Client IDs -> iOS).
  /// Digunakan khusus saat aplikasi berjalan di platform iOS.
  static const String iosClientId =
      '514445291536-o9oot6ilqj8fm0380f160obe4o0vhh15.apps.googleusercontent.com';
}
