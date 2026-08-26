class ApiConfig {
  // =========================================================================
  // BASE URL API BUKU TAMU
  // =========================================================================
  // 📍 SAAT INI (DEVELOPMENT LOKAL):
  // - Jika run di Windows / Desktop / Web: 'http://localhost:8000/api' (atau http://localhost/mboistat/api)
  // - Jika run di Android Emulator: 'http://10.0.2.2:8000/api'
  //
  // 🚀 NANTI JIKA SUDAH ONLINE (PRODUCTION):
  // Tinggal ganti baris baseUrl di bawah ini ke domain API online asli Anda!
  // Contoh: static const String baseUrl = 'https://bukutamu-bps.go.id/api';
  // =========================================================================

  static const String baseUrl = 'http://localhost';

  // Endpoint pencarian customer berdasarkan email
  static const String customerEndpoint = '/api_customers.php';
}
