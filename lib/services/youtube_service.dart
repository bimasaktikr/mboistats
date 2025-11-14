import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:mboistats/models/youtube_video.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. TAMBAHKAN IMPORT INI

class YoutubeService {
  // --- PERSIAPAN UNTUK API PRODUKSI ---
  
  // --- PERUBAHAN DI SINI ---
  // SEBELUM:
  // static const String _apiDomain = "api.server-anda.com";
  
  // SESUDAH:
  // Ganti 'const' menjadi 'final' dan baca dari dotenv.env
  static final String _apiDomain = dotenv.env['API_DOMAIN']!;
  // --- AKHIR PERUBAHAN ---
  
  static const String _apiPath = "/v1/youtube/videos";
  // --- AKHIR PERSIAPAN ---

  // Format tanggal yang akan kita kirim ke API (standar ISO 8601)
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// Mengambil video dari API Backend (Python)
  Future<YoutubeVideoResult> getVideos({
    int page = 1,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
  }) async {
    // Siapkan parameter query
    var params = {
      'page': page.toString(),
    };

    // Tambahkan filter tanggal jika ada
    if (publishedAfter != null) {
      params['after'] = _apiDateFormat.format(publishedAfter);
    }
    if (publishedBefore != null) {
      params['before'] = _apiDateFormat.format(publishedBefore);
    }
    if (_apiDomain.isEmpty) {
      log("FATAL: API Domain tidak terkonfigurasi.", name: "YoutubeService");
      // Jangan panggil API. Langsung lempar error yang jelas.
      throw Exception("Konfigurasi server tidak valid. Harap hubungi support.");
    }


    // Gunakan Uri.https karena server produksi pasti aman (HTTPS)
    final uri = Uri.https(_apiDomain, _apiPath, params);

    log("Memanggil API Produksi: $uri", name: "YoutubeService");

    try {
      // Ganti http.get dengan header jika nanti diperlukan (misal: API Key)
      // final response = await http.get(uri, headers: {
      //   'X-API-Key': 'KUNCI_API_DARI_BACKEND_ANDA'
      // });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cek jika API Python mengembalikan JSON error
        if (data.containsKey('error')) {
          log("Error dari API Python: ${data['details'] ?? data['error']}",
              name: "YoutubeService");
          throw Exception("Error Server: ${data['error']}");
        }

        // Parsing data JSON dari server.
        // INI AKAN BERHASIL JIKA backend Anda mengikuti "Kontrak API"
        // yang kita tetapkan di 'docs/kontrak_api_youtube.md'
        return YoutubeVideoResult.fromJson(data);
      } else {
        // Tangani error dari server (404, 500, 403, dll.)
        log(
            "Error panggil API: Status ${response.statusCode}, Body: ${response.body}",
            name: "YoutubeService");
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      log("Error koneksi ke API: $e", name: "YoutubeService");
      throw Exception(
          "Gagal terhubung ke Server. Periksa koneksi internet Anda.");
    }
  }
}